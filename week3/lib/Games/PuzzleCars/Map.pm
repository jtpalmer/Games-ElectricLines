package Games::PuzzleCars::Map;
use Mouse;
use SDL::Rect;
use SDL::Event;
use SDL::Events;
use SDLx::Surface;
use SDLx::Sprite;
use Games::PuzzleCars::Intersection;

has background => (
    is       => 'ro',
    isa      => 'SDLx::Surface',
    required => 1,
);

has roads => (
    is       => 'ro',
    isa      => 'ArrayRef[ArrayRef]',
    required => 1,
);

has intersections => (
    is       => 'ro',
    isa      => 'ArrayRef',
    default  => sub { [] },
    required => 1,
);

has tile_w => (
    is       => 'ro',
    isa      => 'Int',
    required => 1,
);

has tile_h => (
    is       => 'ro',
    isa      => 'Int',
    required => 1,
);

around BUILDARGS => sub {
    my ( $orig, $class, %args ) = @_;

    my ( @roads, @intersections );

    my $bg = SDLx::Surface->new(
        w     => $args{w},
        h     => $args{h},
        color => 0x000000FF,
    );

    my $arrow = SDLx::Sprite->new( image => $args{intersection}{image} );
    $arrow->alpha_key(0x000000);

    my $road_sprite = SDLx::Sprite->new( image => $args{roads}{image} );
    open my $map_file, '<', $args{file};
    my @map = map { chomp; [ split //, $_ ] } <$map_file>;
    my ( $x, $y );
    foreach my $row_id ( 0 .. $#map ) {
        my @row = @{ $map[$row_id] };
        foreach my $col_id ( 0 .. $#row ) {

            my ( $prev_row, $next_row ) = ( $row_id - 1, $row_id + 1 );
            $prev_row = $row_id + 1 if $row_id == 0;
            $next_row = $row_id - 1 if $row_id == $#map;
            my @v = ( $map[$prev_row][$col_id], $map[$next_row][$col_id] );

            my ( $prev_col, $next_col ) = ( $col_id - 1, $col_id + 1 );
            $prev_col = $col_id + 1 if $col_id == 0;
            $next_col = $col_id - 1 if $col_id == $#row;
            my @h = ( $map[$row_id][$prev_col], $map[$row_id][$next_col] );

            foreach my $y_offset ( 0, 1 ) {
                foreach my $x_offset ( 0, 1 ) {

                    my $cell = $map[$row_id][$col_id];

                    my $index = 0;
                    if ( $cell eq 'R' ) {
                        push @roads, [ $col_id, $row_id ];
                        if ( 2 < grep { $_ eq 'R' } ( @h, @v ) ) {
                            push @intersections,
                                Games::PuzzleCars::Intersection->new(
                                x => ( $col_id + 0.5 ) * $args{roads}{w} * 2,
                                y => ( $row_id + 0.5 ) * $args{roads}{h} * 2,
                                arrow => $arrow,
                                %{ $args{intersection} },
                                );
                        }

                        $index += 1 if $v[$y_offset] eq 'R';
                        $index += 2 if $h[$x_offset] eq 'R';
                    }
                    else {
                        $index = 4;
                    }

                    my @tiles = @{ $args{roads}{mapping}
                            [ 2 * $y_offset + $x_offset ] };

                    my @tile_group = @{ $tiles[$index] };
                    my @tile       = @{ $tile_group[ int rand @tile_group ] };
                    $x = $tile[0];
                    $y = $tile[1];

                    $road_sprite->clip(
                        [   $x * $args{roads}{w}, $y * $args{roads}{h},
                            $args{roads}{w},      $args{roads}{h}
                        ]
                    );
                    $road_sprite->draw_xy(
                        $bg,
                        ( 2 * $col_id + $x_offset ) * $args{roads}{w},
                        ( 2 * $row_id + $y_offset ) * $args{roads}{h}
                    );
                }
            }
        }
    }

    $args{tile_w}        = $args{roads}{w} * 2;
    $args{tile_h}        = $args{roads}{h} * 2;
    $args{background}    = $bg;
    $args{roads}         = \@roads;
    $args{intersections} = \@intersections;

    return $class->$orig(%args);
};

sub handle_event {
    my ( $self, $event ) = @_;

    return unless $event->type == SDL_MOUSEBUTTONDOWN;

    $_->handle_event($event) foreach @{ $self->intersections };
}

sub draw {
    my ( $self, $surface ) = @_;

    $self->background->blit($surface);
    $_->draw($surface) foreach @{ $self->intersections };
}

no Mouse;

1;
