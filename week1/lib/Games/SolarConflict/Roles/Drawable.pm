package Games::SolarConflict::Roles::Drawable;
use Mouse::Role;

requires qw( draw );

has visible => (
    is      => 'rw',
    isa     => 'Bool',
    default => 1,
);

around draw => sub {
    my ( $orig, $self, $surface ) = @_;

    return unless $self->visible;

    return $self->$orig($surface);
};

no Mouse::Role;

1;
