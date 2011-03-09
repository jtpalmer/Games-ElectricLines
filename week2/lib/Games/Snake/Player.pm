package Games::Snake::Player;
use Mouse;

has segments => (
    is      => 'ro',
    isa     => 'ArrayRef',
    default => sub { [] },
);

has speed => (
    is      => 'rw',
    isa     => 'Num',
    default => 0,
);

has direction => (
    is      => 'rw',
    isa     => 'ArrayRef',
    default => sub { [] },
);

has growing => (
    is      => 'rw',
    isa     => 'Int',
    default => 0,
);

has size => (
    is       => 'ro',
    isa      => 'Int',
    required => 1,
);

has color => (
    is       => 'ro',
    isa      => 'Int',
    required => 1,
);

sub head {
    my ($self) = @_;
    return $self->segments->[0];
}

sub body {
    my ($self) = @_;
    return [ @{ $self->segments }[ 1, -1 ] ];
}

sub move {
    my ($self) = @_;

    my $segments = $self->segments;

    my @head = @{ $self->head };
    my @d    = @{ $self->direction };
    unshift @$segments, [ $head[0] + $d[0], $head[1] + $d[1] ];

    if ( my $grow = $self->growing ) {
        $self->growing( $grow - 1 );
    }
    else {
        pop @$segments;
    }
}

sub draw {
    my ( $self, $surface ) = @_;

    my $size  = $self->size;
    my $color = $self->color;

    foreach my $segment ( @{ $self->segments } ) {
        $surface->draw_rect(
            [ ( map { $_ * $size } @$segment ), $size, $size ], $color );
    }
}

no Mouse;

1;
