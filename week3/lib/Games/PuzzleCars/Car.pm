package Games::PuzzleCars::Car;
use Mouse;
use Games::PuzzleCars::Sprite;

has [qw( x y rot v_x v_y )] => (
    is       => 'rw',
    isa      => 'Num',
    required => 1,
);

has direction => (
    is       => 'rw',
    isa      => 'Str',
    required => 1,
);

has turn => (
    is      => 'rw',
    isa     => 'HashRef',
    clearer => '_clear_turn',
    default => sub { {} },
);

has map => (
    is       => 'ro',
    isa      => 'Games::PuzzleCars::Map',
    required => 1,
);

has road => (
    is       => 'rw',
    isa      => 'Games::PuzzleCars::Road',
    required => 1,
);

has next_road => (
    is  => 'rw',
    isa => 'Games::PuzzleCars::Road',
    clearer => '_clear_next_road',
);

has _sprite => (
    is       => 'ro',
    isa      => 'Games::PuzzleCars::Sprite',
    required => 1,
    handles  => [qw( draw )],
);

around BUILDARGS => sub {
    my ( $orig, $class, %args ) = @_;

    my $sprite = Games::PuzzleCars::Sprite->new(
        rect    => $args{rect},
        surface => $args{surface},
    );

    return $class->$orig( _sprite => $sprite, %args );
};

before draw => sub {
    my ($self) = @_;

    my $sprite = $self->_sprite;
    my $rect   = $sprite->rect;

    $sprite->x( $self->x - $rect->w / 2 );
    $sprite->y( $self->y - $rect->h / 2 );
    $sprite->rotation( $self->rot );
};

sub move {
    my ( $self, $step, $c, $t ) = @_;

    if ( my %turn = %{ $self->turn } ) {
    }
    else {
        $self->x( $self->x + $self->v_x * $step );
        $self->y( $self->y + $self->v_y * $step );
    }

    if (   $self->next_road
        && $self->next_road->contains( $self->x, $self->y ) )
    {
        my $new_next = $self->next_road->next( $self->direction );
        $self->road( $self->next_road );
        if ( $new_next ) {
            $self->next_road($new_next);
        }
        else {
            warn 'clearing next road';
            $self->_clear_next_road();
        }
    }
}

no Mouse;

1;
