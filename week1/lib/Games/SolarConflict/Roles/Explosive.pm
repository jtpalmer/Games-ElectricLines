package Games::SolarConflict::Roles::Explosive;
use Mouse::Role;
use SDLx::Sprite::Animated;

requires qw( x y rect draw visible );

has exploding => (
    is      => 'rw',
    isa     => 'Bool',
    default => 0,
);

has explosion => (
    is       => 'ro',
    isa      => 'SDLx::Sprite::Animated',
    required => 1,
);

around draw => sub {
    my ( $orig, $self, $surface ) = @_;

    if ( $self->exploding ) {
        if ( $self->explosion->current_loop != 1 ) {
            $self->exploding(0);
            $self->visible(0);
            return;
        }
        $self->explosion->x( $self->x - $self->rect->w / 2 );
        $self->explosion->y( $self->y - $self->rect->h / 2 );
        return $self->explosion->draw($surface);
    }
    else {
        return $self->$orig($surface);
    }
};

sub explode {
    my ($self) = @_;

    $self->exploding(1);
    $self->explosion->start();
}

no Mouse::Role;

1;
