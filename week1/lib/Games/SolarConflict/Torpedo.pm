package Games::SolarConflict::Torpedo;
use Moose;
use SDL::Color;
use SDL::GFX::Primitives;
use namespace::clean -except => 'meta';

with 'Games::SolarConflict::Roles::Drawable';
with 'Games::SolarConflict::Roles::Physical';

has r => (
    is      => 'ro',
    isa     => 'Num',
    default => 3,
);

has color => (
    is      => 'ro',
    isa     => 'SDL::Color',
    default => sub { SDL::Color->new( 255, 255, 255 ) },
);

has '+mass' => ( default => 0.01 );

sub draw {
    my ( $self, $surface ) = @_;

    SDL::GFX::Primitives::filled_circle_RGBA( $surface, $self->x, $self->y,
        $self->r, 255, 255, 255, 255 );

    #SDL::GFX::Primitives::filled_circle_color( $surface, $self->x, $self->y,
    #$self->r, $self->color );
}

__PACKAGE__->meta->make_immutable;

1;
