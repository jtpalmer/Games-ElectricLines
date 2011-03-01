package Games::SolarConflict::Sprite::Rotatable;
use Moose;
use MooseX::NonMoose;
use SDLx::Sprite::Animated;
use namespace::clean -except => 'meta';

extends 'SDLx::Sprite::Animated';

has map => (
    is  => 'ro',
    isa => 'ArrayRef[]',
);

has increment => (
    is      => 'ro',
    isa     => 'Int',
    lazy    => 1,
    default => sub { 360 / ( $_[0]->rows * $_[0]->cols ) },
);

has rows => (
    is      => 'ro',
    isa     => 'Int',
    lazy    => 1,
    default => sub { $_[0]->h / $_[0]->rect->h },
);

has cols => (
    is      => 'ro',
    isa     => 'Int',
    lazy    => 1,
    default => sub { $_[0]->w / $_[0]->rect->w },
);

sub rotation {
    my ( $self, $rot ) = @_;

    while ($rot > 360) { $rot -= 360 }
    while ($rot < 0) { $rot += 360 }

    my $frame = int( $rot / $self->increment );

    my $clip = $self->clip;
    $clip->x( ($frame % $self->cols) * $self->rect->h );
    $clip->y( int($frame / $self->cols) * $self->rect->w );
}

__PACKAGE__->meta->make_immutable;

1;
