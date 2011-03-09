package Games::Snake::Level;
use Mouse;

has [qw( w h )] => (
    is       => 'ro',
    isa      => 'Int',
    required => 1,
);

has walls => (
    is      => 'ro',
    isa     => 'ArrayRef',
    lazy    => 1,
    builder => '_build_walls',
);

has size => (
    is       => 'ro',
    isa      => 'Int',
    required => 1,
);

has color => (
    is      => 'ro',
    isa     => 'Int',
    default => 0x0000FFFF,
);

sub _build_walls {
    my ($self) = @_;

    my @walls;

    my $w = $self->w;
    my $h = $self->h;

    foreach my $x ( 0 .. $w - 1 ) {
        push @walls, [ $x, 0 ], [ $x, $h - 1 ];
    }

    foreach my $y ( 1 .. $self->w - 2 ) {
        push @walls, [ 0, $y ], [ $w - 1, $y ];
    }

    return \@walls;
}

sub is_wall {
    my ( $self, $coord ) = @_;
    return
        scalar grep { $coord->[0] == $_->[0] && $coord->[1] == $_->[1] }
        @{ $self->walls };
}

sub draw {
    my ( $self, $surface ) = @_;

    my $size  = $self->size;
    my $color = $self->color;

    foreach my $wall ( @{ $self->walls } ) {
        $surface->draw_rect( [ ( map { $_ * $size } @$wall ), $size, $size ],
            $color );
    }
}

no Mouse;

1;
