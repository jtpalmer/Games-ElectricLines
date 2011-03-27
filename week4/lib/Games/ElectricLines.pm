package Games::ElectricLines;
use Mouse;
use FindBin qw( $Bin );
use File::Spec;
use SDL;
use SDL::Rect;
use SDLx::App;
use SDLx::Sprite::Animated;

has _share_dir => (
    is      => 'ro',
    isa     => 'Str',
    default => sub { File::Spec->catdir( $Bin, 'share' ) },
);

has app => (
    is      => 'ro',
    isa     => 'SDLx::App',
    builder => '_build_app',
    handles => [qw( run )],
);

has sprite => (
    is      => 'ro',
    isa     => 'SDLx::Sprite::Animated',
    lazy    => 1,
    builder => '_build_sprite',
);

has _starting_points => (
    is      => 'ro',
    isa     => 'ArrayRef',
    lazy    => 1,
    builder => '_build_starting_points',
);

has _horizontal_lines => (
    is      => 'ro',
    isa     => 'ArrayRef',
    lazy    => 1,
    builder => '_build_horizontal_lines',
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
        ticks_per_frame => 2,
    );
    $sprite->alpha_key(0x000000);
    $sprite->start();
    return $sprite;
}

sub _build_starting_points {
    my ($self) = @_;

    my $count = 4;

    my $app   = $self->app;
    my $space = $app->h / $count;
    my $x    = 0;

    my @points;

    foreach my $i ( 1 .. $count ) {
        my $y = ( $i - 0.5 ) * $space;
        push @points, [ $x, $y ];
    }

    return \@points;
}

sub _build_horizontal_lines {
    my ($self) = @_;

    my $x  = $self->app->w;

    my @lines;
    foreach my $point ( @{ $self->_starting_points } ) {
        push @lines, [ $point, [ $x, $point->[1] ] ];
    }

    return \@lines;
}

sub BUILD {
    my ($self) = @_;

    my $app = $self->app;
    $app->add_event_handler( sub { $self->handle_event(@_) } );
    $app->add_move_handler( sub  { $self->handle_move(@_) } );
    $app->add_show_handler( sub  { $self->handle_show(@_) } );
}

sub handle_event {
    my ( $self, $event, $app ) = @_;
}

sub handle_move {
    my ( $self, $step, $app, $t ) = @_;
}

sub handle_show {
    my ( $self, $delta, $app ) = @_;

    $app->draw_rect( undef, undef );
    foreach my $line ( @{ $self->_horizontal_lines } ) {
        $app->draw_line( @$line, 0xFFFFFFFF );
    }
    $self->sprite->draw($app);
    $app->update();
}

no Mouse;

1;
