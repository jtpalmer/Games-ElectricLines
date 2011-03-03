package Games::SolarConflict::Torpedo;
use Mouse;
use SDL::Color;
use SDL::GFX::Primitives;
use namespace::clean -except => 'meta';

with 'Games::SolarConflict::Roles::Drawable';
with 'Games::SolarConflict::Roles::Physical';

has '+r' => ( default => 3 );

has '+mass' => ( default => 1 );

has '+valid' => ( default => 0 );

has color => (
    is      => 'ro',
    isa     => 'Int',
    default => 0xFFFFFFFF,
);

# torpedos have negligible gravitational force
sub force_on { ( 0, 0 ) }

sub interact {
    my ( $self, $obj ) = @_;

    $self->valid(0);
}

sub draw {
    my ( $self, $surface ) = @_;

    SDL::GFX::Primitives::filled_circle_color( $surface, $self->x, $self->y,
        $self->r, $self->color );
}

__PACKAGE__->meta->make_immutable;

1;
