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
        foreach my $col_id ( 0 .. $#row ) {

            my ( $prev_row, $next_row ) = ( $row_id - 1, $row_id + 1 );
            $prev_row = $row_id + 1 if $row_id == 0;
            $next_row = $row_id - 1 if $row_id == $#roads;
            my @vertical
                = ( $roads[$prev_row][$col_id], $roads[$next_row][$col_id] );

            my ( $prev_col, $next_col ) = ( $col_id - 1, $col_id + 1 );
            $prev_col = $col_id + 1 if $col_id == 0;
            $next_col = $col_id - 1 if $col_id == $#row;
            my @horizontal
                = ( $roads[$row_id][$prev_col], $roads[$row_id][$next_col] );

            foreach my $y_offset ( 0, 1 ) {
                foreach my $x_offset ( 0, 1 ) {

                    my $index = 0;
                    if ( $roads[$row_id][$col_id] eq 'R' ) {
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
                        ( 2 * $col_id + $x_offset ) * $args{roads}{w},
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
