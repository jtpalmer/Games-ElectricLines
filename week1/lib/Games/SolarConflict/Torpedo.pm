package Games::SolarConflict::Torpedo;
use Mouse;
use SDL::Color;
use SDL::GFX::Primitives;

with 'Games::SolarConflict::Roles::Drawable';
with 'Games::SolarConflict::Roles::Physical';

has '+r' => ( default => 3 );

has '+mass' => ( default => 10 );

has '+active' => ( default => 0 );

has '+visible' => ( default => 0 );

has color => (
    is      => 'ro',
    isa     => 'Int',
    default => 0xFFFFFFFF,
);

after active => sub {
    my ( $self, $active ) = @_;
    $self->visible($active) if defined $active;
};

# torpedos have negligible gravitational force
sub force_on { ( 0, 0 ) }

sub interact {
    my ( $self, $obj ) = @_;

    $self->active(0);
}

sub draw {
    my ( $self, $surface ) = @_;

    SDL::GFX::Primitives::filled_circle_color( $surface, $self->x, $self->y,
        $self->r, $self->color );
}

__PACKAGE__->meta->make_immutable;

no Mouse;

1;
