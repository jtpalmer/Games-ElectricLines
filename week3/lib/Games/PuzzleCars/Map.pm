package Games::PuzzleCars::Map;
use Mouse;
use SDL::Rect;
use SDLx::Surface;
use SDLx::Sprite;

has background => (
    is       => 'ro',
    isa      => 'SDLx::Surface',
    required => 1,
);

has roads => ( is => 'ro', );

has intersections => (
    is  => 'ro',
    isa => 'ArrayRef',
);

around BUILDARGS => sub {
    my ( $orig, $class, %args ) = @_;

    my $bg = SDLx::Surface->new(
        w     => $args{w},
        h     => $args{h},
        color => 0x000000FF,
    );

    my $road_sprite = SDLx::Sprite->new( image => $args{roads}{image} );
    open my $road_file, '<', $args{roads}{file};
    my @roads = map { chomp; [ split //, $_ ] } <$road_file>;
    my ( $x, $y );
    foreach my $row_id ( 0 .. $#roads ) {
        my @row = @{ $roads[$row_id] };
        foreach my $column_id ( 0 .. $#row ) {

            my ( @vertical, @horizontal );

            if ( $row_id == 0 ) {
                @vertical = (
                    $roads[ $row_id + 1 ][$column_id],
                    $roads[ $row_id + 1 ][$column_id]
                );
            }
            elsif ( $row_id == $#roads ) {
                @vertical = (
                    $roads[ $row_id - 1 ][$column_id],
                    $roads[ $row_id - 1 ][$column_id]
                );
            }
            else {
                @vertical = (
                    $roads[ $row_id - 1 ][$column_id],
                    $roads[ $row_id + 1 ][$column_id]
                );
            }

            if ( $column_id == 0 ) {
                @horizontal = (
                    $roads[$row_id][ $column_id + 1 ],
                    $roads[$row_id][ $column_id + 1 ]
                );
            }
            elsif ( $column_id == $#row ) {
                @horizontal = (
                    $roads[$row_id][ $column_id - 1 ],
                    $roads[$row_id][ $column_id - 1 ]
                );
            }
            else {
                @horizontal = (
                    $roads[$row_id][ $column_id - 1 ],
                    $roads[$row_id][ $column_id + 1 ]
                );
            }

            foreach my $y_offset ( 0, 1 ) {
                foreach my $x_offset ( 0, 1 ) {

                    my $index = 0;
                    if ( $roads[$row_id][$column_id] eq 'R' ) {
                        $index += 1 if $vertical[$y_offset]   eq 'R';
                        $index += 2 if $horizontal[$x_offset] eq 'R';
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
                        ( 2 * $column_id + $x_offset ) * $args{roads}{w},
                        ( 2 * $row_id + $y_offset ) * $args{roads}{h}
                    );
                }
            }
        }
    }

    $args{background} = $bg;

    return $class->$orig(%args);
};

sub draw {
    my ( $self, $surface ) = @_;

    $self->background->blit($surface);
}

no Mouse;

1;
