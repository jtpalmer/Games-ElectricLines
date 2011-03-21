package Games::PuzzleCars::Road;
use Mouse;

has map => (
    is       => 'ro',
    isa      => 'Games::PuzzleCars::Map',
    required => 1,
);

has [qw( x y )] => (
    is       => 'ro',
    isa      => 'Int',
    required => 1,
);

has directions => (
    is       => 'ro',
    isa      => 'HashRef',
    required => 1,
);

sub next {
    my ( $self, $direction ) = @_;

    if ( !defined $self->directions->{$direction} ) {
        my %opposite = (
            WEST  => 'EAST',
            EAST  => 'WEST',
            NORTH => 'SOUTH',
            SOUTH => 'NORTH',
        );

        ($direction)
            = grep { $_ ne $opposite{$direction} }
            keys %{ $self->directions };
    }

    my $x = $self->x;
    my $y = $self->y;
    $x += 1 if $direction eq 'EAST';
    $x -= 1 if $direction eq 'WEST';
    $y += 1 if $direction eq 'NORTH';
    $y -= 1 if $direction eq 'SOUTH';

    my $roads = $self->map->roads;
    return undef unless defined $roads->[$x][$y];

    return $roads->[$x][$y];
}

sub contains {
    my ( $self, $x, $y ) = @_;

    my $map = $self->map;
    return
           $x >= $self->x * $map->tile_w
        && $x < ( $self->x + 1 ) * $map->tile_w
        && $y >= $self->y * $map->tile_h
        && $y < ( $self->y + 1 ) * $map->tile_h;
}

no Mouse;

1;
