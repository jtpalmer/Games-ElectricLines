package Games::PuzzleCars::Intersection;
use Mouse;

extends 'Games::PuzzleCars::Road';

has direction => (
    is      => 'rw',
    isa     => 'Int',
    default => 0,
);

has arrow => (
    is       => 'ro',
    isa      => 'SDLx::Sprite',
    required => 1,
);

# TODO: sub next {

sub handle_event {
    my ( $self, $event ) = @_;

    my $e_x = $event->button_x;
    my $e_y = $event->button_y;

    my $x      = ( $self->x + 0.5 ) * $self->map->tile_w;
    my $y      = ( $self->y + 0.5 ) * $self->map->tile_h;
    my $s      = $self->arrow->h;
    my $left   = $x - $s / 2;
    my $right  = $x + $s / 2;
    my $top    = $y - $s / 2;
    my $bottom = $y + $s / 2;

    return
        unless $e_x > $left && $e_x < $right && $e_y > $top && $e_y < $bottom;

    $self->direction( ( $self->direction + 1 ) % 3 );
}

sub draw {
    my ( $self, $surface ) = @_;

    my $arrow = $self->arrow;
    my $x     = ( $self->x + 0.5 ) * $self->map->tile_w;
    my $y     = ( $self->y + 0.5 ) * $self->map->tile_h;
    my $s     = $arrow->h;
    $arrow->clip( [ $self->direction * $s, 0, $s, $s ] );
    $arrow->draw_xy( $surface, $x - $s / 2, $y - $s / 2 );
}

no Mouse;

1;
