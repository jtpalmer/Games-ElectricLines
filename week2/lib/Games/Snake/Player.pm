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

has alive => (
    is      => 'rw',
    isa     => 'Bool',
    default => 1,
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
    my @segments = @{ $self->segments };
    return [ @segments[ 1 .. $#segments ] ];
}

sub move {
    my ($self) = @_;

    return unless $self->alive;

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

sub hit_self {
    my ($self) = @_;

    my @head = @{ $self->head };
    return
        scalar grep { $head[0] == $_->[0] && $head[1] == $_->[1] }
        @{ $self->body };
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
