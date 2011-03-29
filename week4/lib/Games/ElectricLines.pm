package Games::ElectricLines;
use Mouse;
use FindBin qw( $Bin );
use File::Spec;
use SDL;
use SDL::Event;
use SDL::Events;
use SDL::Rect;
use SDLx::App;
use SDLx::Text;
use SDLx::Sprite::Animated;

has _share_dir => (
    is      => 'ro',
    isa     => 'Str',
    default => sub { File::Spec->catdir( $Bin, 'share' ) },
);

has _app => (
    is      => 'ro',
    isa     => 'SDLx::App',
    builder => '_build_app',
    handles => [qw( run )],
);

has _sprite => (
    is      => 'ro',
    isa     => 'SDLx::Sprite::Animated',
    lazy    => 1,
    builder => '_build_sprite',
);

has _horizontal_lines => (
    is      => 'ro',
    isa     => 'ArrayRef',
    lazy    => 1,
    builder => '_build_horizontal_lines',
);

has _active_line => (
    is        => 'rw',
    isa       => 'ArrayRef',
    clearer   => '_clear_active_line',
    predicate => '_has_active_line',
);

has _crossing_lines => (
    is      => 'ro',
    isa     => 'ArrayRef',
    default => sub { [] },
);

has _plasma => (
    is      => 'ro',
    isa     => 'ArrayRef',
    default => sub { [] },
);

has _plasma_frequency => (
    is      => 'rw',
    isa     => 'Num',
    default => 10,
);

has _plasma_time => (
    is      => 'rw',
    isa     => 'Num',
    default => 0,
);

has _row_count => (
    is      => 'ro',
    isa     => 'Int',
    default => 4,
);

has _exit_count => (
    is      => 'ro',
    isa     => 'Int',
    default => 2,
);

has _label => (
    is      => 'ro',
    isa     => 'SDLx::Text',
    default => sub {
        SDLx::Text->new( x => 5, y => 5, size => 24, color => 0xFFFFFF );
    },
);

has _exits => (
    is      => 'ro',
    isa     => 'ArrayRef',
    builder => '_build_exits',
);

has _score => (
    is      => 'rw',
    isa     => 'Int',
    default => 0,
);

has _lives => (
    is      => 'rw',
    isa     => 'Int',
    default => 3,
);

sub _build_app {
    return SDLx::App->new(
        title => 'Electric Lines',
        w     => 800,
        h     => 600,
        delay => 30,
        eoq   => 1,
    );
}

sub _build_sprite {
    my ($self) = @_;

    my $sprite = SDLx::Sprite::Animated->new(
        rect => SDL::Rect->new( 0, 50, 50, 50 ),
        image => File::Spec->catfile( $self->_share_dir, 'plasma.bmp' ),
    );
    $sprite->alpha_key(0x000000);
    $sprite->start();
    return $sprite;
}

sub _starting_points {
    my ($self) = @_;
    return [ map { $_->[0] } @{ $self->_horizontal_lines } ];
}

sub _ending_points {
    my ($self) = @_;
    return [ map { $_->[1] } @{ $self->_horizontal_lines } ];
}

sub _build_horizontal_lines {
    my ($self) = @_;

    my $count = $self->_row_count;
    my $app   = $self->_app;
    my $space = $app->h / $count;

    my $x0 = $self->_sprite->rect->w / 2;
    my $x1 = $app->w - $self->_sprite->rect->w / 2;

    my @lines;
    foreach my $i ( 1 .. $count ) {
        my $y = ( $i - 0.5 ) * $space;
        push @lines, [ [ $x0, $y ], [ $x1, $y ] ];
    }

    return \@lines;
}

sub _build_exits {
    my ($self) = @_;

    my @exits;
    my @ends = @{ $self->_ending_points };
    foreach my $i ( 1 .. $self->_exit_count ) {
        my $n = int rand @ends;
        push @exits, splice( @ends, $n, 1 );
    }

    return \@exits;
}

sub BUILD {
    my ($self) = @_;

    $self->_add_plasma();

    my $app = $self->_app;
    $app->add_event_handler( sub { $self->handle_event(@_) } );
    $app->add_move_handler( sub  { $self->handle_move(@_) } );
    $app->add_show_handler( sub  { $self->handle_show(@_) } );
}

sub handle_event {
    my ( $self, $event, $app ) = @_;

    if ( $event->type == SDL_MOUSEBUTTONDOWN ) {
        return unless $event->button_button == SDL_BUTTON_LEFT;
        my $x = $event->button_x;
        my $y = $event->button_y;
        $self->_active_line( [ [ $x, $y ], [ $x, $y ] ] );
    }
    elsif ( $event->type == SDL_MOUSEMOTION ) {
        return unless $self->_has_active_line();
        my $x = $event->motion_x;
        my $y = $event->motion_y;
        $self->_active_line->[1] = [ $x, $y ];
    }
    elsif ( $event->type == SDL_MOUSEBUTTONUP ) {
        return unless $event->button_button == SDL_BUTTON_LEFT;
        my $x = $event->button_x;
        my $y = $event->button_y;
        $self->_active_line->[1] = [ $x, $y ];
        $self->_store_active_line();
        $self->_clear_active_line();
    }
}

sub _store_active_line {
    my ($self) = @_;
    my $segments = $self->_segment_line( $self->_active_line );
    push @{ $self->_crossing_lines }, @{ $segments->{good} };
}

sub handle_move {
    my ( $self, $step, $app, $t ) = @_;

    return unless $self->_lives > 0;

    if ( $t > $self->_plasma_time + $self->_plasma_frequency ) {
        $self->_plasma_time($t);
        $self->_add_plasma();
    }

    my @plasma;
    foreach my $plasma ( @{ $self->_plasma } ) {
        $self->_move_plasma( $plasma, $step );
        if ( $plasma->{x} < $app->w - $self->_sprite->rect->w / 2 ) {
            push @plasma, $plasma;
        }
        else {
            if ( grep { $plasma->{y} == $_->[1] } @{ $self->_exits } ) {
                $self->_score( $self->_score + 1 );
            }
            else {
                $self->_lives( $self->_lives - 1 );
            }
        }
    }

    if ( $self->_lives <= 0 ) {
        $self->_lives(0);
        @{ $self->_plasma } = ();
    }
    else {
        @{ $self->_plasma } = @plasma;
    }
}

sub handle_show {
    my ( $self, $delta, $app ) = @_;

    $app->draw_rect( undef, undef );

    foreach my $line ( @{ $self->_horizontal_lines },
        @{ $self->_crossing_lines } )
    {
        $app->draw_line( @$line, 0xFFFFFFFF );
    }

    my $radius = $self->_sprite->rect->w / 2;
    foreach my $point ( @{ $self->_starting_points } ) {
        $app->draw_circle_filled( $point, $radius, 0xFFFFFFFF );
    }
    foreach my $point ( @{ $self->_ending_points } ) {
        $app->draw_circle_filled( $point, $radius, 0xFF0000FF );
    }
    foreach my $exit ( @{ $self->_exits } ) {
        $app->draw_circle_filled( $exit, $radius, 0x00FF00FF );
    }

    if ( $self->_has_active_line() ) {
        $self->_draw_active_line( $self->_active_line );
    }

    $self->_sprite->ticks_per_frame( 2 * @{ $self->_plasma } );
    foreach my $plasma ( @{ $self->_plasma } ) {
        $self->_draw_plasma($plasma);
    }

    $self->_label->write_to( $app,
        'Lives: ' . $self->_lives . ' -- Score: ' . $self->_score );

    $app->update();
}

sub _move_plasma {
    my ( $self, $plasma, $step ) = @_;

    $step *= 3;

    if ( defined $plasma->{crossing} ) {
        my ( $line, $direction )
            = @{ $plasma->{crossing} }{qw( line direction )};
        my $y = $plasma->{y};
        $y += $direction * $step;

        my $end = $line->[1];
        if ( ( $y <=> $end->[1] ) == $direction ) {
            $plasma->{x} = $end->[0];
            $plasma->{y} = $end->[1];
            delete $plasma->{crossing};
        }
        else {
            my $x = $self->_interpolate_x( $line, $y );
            $plasma->{x} = $x;
            $plasma->{y} = $y;
        }
    }
    else {
        my $y  = $plasma->{y};
        my $x0 = $plasma->{x};
        my $x1 = $x0 + $step;

        my ($crossing) = map { $_->[1] }
            sort { $a->[0] <=> $b->[0] }
            grep { $_->[0] > $x0 && $x1 >= $_->[0] } map {
                  $_->[0][1] == $y ? [ $_->[0][0], [ $_->[0], $_->[1] ] ]
                : $_->[1][1] == $y ? [ $_->[1][0], [ $_->[1], $_->[0] ] ]
                : ()
            } @{ $self->_crossing_lines };

        if ($crossing) {
            $plasma->{crossing} = {
                line      => $crossing,
                direction => ( $crossing->[1][1] <=> $crossing->[0][1] ),
            };
        }
        else {
            $plasma->{x} = $x1;
        }
    }
}

sub _draw_active_line {
    my ( $self, $line ) = @_;

    my $segments = $self->_segment_line($line);

    foreach my $line ( @{ $segments->{good} } ) {
        $self->_app->draw_line( @$line, 0x00FF00FF );
    }
    foreach my $line ( @{ $segments->{bad} } ) {
        $self->_app->draw_line( @$line, 0xFF0000FF );
    }
}

sub _segment_line {
    my ( $self, $line ) = @_;

    my ( $x0, $y0, $x1, $y1 ) = map {@$_} @$line;

    my @good;
    my @bad;

    my $direction = $y0 <=> $y1;
    if ( $direction == 0 ) {
        push @bad, $line;
    }
    else {
        my @rows = grep {
                   ( $y0 <=> $_->[0][1] ) == $direction
                && ( $y1 <=> $_->[0][1] )
                != $direction
        } @{ $self->_horizontal_lines };
        @rows = reverse @rows if $direction == 1;

        if ( @rows < 2 ) {
            push @bad, $line;
        }
        else {
            my ( $row0, $row1 ) = @rows[ 0, 1 ];
            my ( $r0_y,  $r1_y )  = ( $row0->[0][1], $row1->[0][1] );
            my ( $r0_x0, $r0_x1 ) = ( $row0->[0][0], $row0->[1][0] );
            my ( $r1_x0, $r1_x1 ) = ( $row1->[0][0], $row1->[1][0] );
            my $s_x0 = $self->_interpolate_x( $line, $r0_y );
            my $s_x1 = $self->_interpolate_x( $line, $r1_y );
            if (   $r0_x0 > $s_x0
                || $s_x0 > $r0_x1
                || $r1_x0 > $s_x1
                || $s_x1 > $r1_x1 )
            {
                push @bad, $line;
            }
            else {
                my @segment = ( [ $s_x0, $r0_y ], [ $s_x1, $r1_y ] );
                push @good, \@segment;
                push @bad, [ $line->[0], $segment[0] ],
                    [ $segment[1], $line->[1] ];
            }
        }
    }

    return {
        good => \@good,
        bad  => \@bad,
    };
}

sub _interpolate_x {
    my ( $self, $line, $y ) = @_;
    my ( $x0, $y0, $x1, $y1 ) = map {@$_} @$line;
    my $m = ( $y1 - $y0 ) / ( $x1 - $x0 );
    my $b = $y0 - $x0 * $m;
    return ( $y - $b ) / $m;
}

sub _draw_plasma {
    my ( $self, $plasma ) = @_;

    my $sprite = $self->_sprite;
    $sprite->x( $plasma->{x} - $sprite->rect->w / 2 );
    $sprite->y( $plasma->{y} - $sprite->rect->h / 2 );
    $sprite->draw( $self->_app );
}

sub _add_plasma {
    my ($self) = @_;

    my @points = @{ $self->_starting_points };
    my $i      = int rand @points;
    my @start  = @{ $points[$i] };
    my $line   = $self->_horizontal_lines->[$i];

    my %plasma = (
        x    => $start[0],
        y    => $start[1],
        line => $line,
    );

    push @{ $self->_plasma }, \%plasma;
}

no Mouse;

1;
