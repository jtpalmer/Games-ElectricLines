package Games::PuzzleCars::Intersection;
use Mouse;

has [qw( x y w h )] => (
    is       => 'ro',
    isa      => 'Int',
    required => 1,
);

has direction => (
    is      => 'rw',
    isa     => 'Int',
    default => 0,
);

has directions => (
    is  => 'ro',
    isa => 'ArrayRef',

    #required => 1,
);

has arrow => (
    is       => 'ro',
    isa      => 'SDLx::Sprite',
    required => 1,
);

sub handle_event {
    my ( $self, $event ) = @_;

    my $x      = $event->button_x;
    my $y      = $event->button_y;
    my $left   = $self->x - $self->w / 2;
    my $right  = $self->x + $self->w / 2;
    my $top    = $self->y - $self->h / 2;
    my $bottom = $self->y + $self->h / 2;

    return unless $x > $left && $x < $right && $y > $top && $y < $bottom;

    $self->direction( ( $self->direction + 1 ) % 3 );
}

sub draw {
    my ( $self, $surface ) = @_;

    my $arrow = $self->arrow;
    $arrow->clip( [ $self->direction * $self->w, 0, $self->w, $self->h ] );
    $arrow->draw_xy(
        $surface,
        $self->x - $self->w / 2,
        $self->y - $self->h / 2
    );
}

no Mouse;

1;
