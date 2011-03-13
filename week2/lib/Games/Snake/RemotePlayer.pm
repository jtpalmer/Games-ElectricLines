package Games::Snake::RemotePlayer;
use Mouse;

extends 'Games::Snake::Player';

has '+size'  => ( default => 1 );
has '+color' => ( default => 0xCCCCCCFF );

has raddr => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has rport => (
    is       => 'ro',
    isa      => 'Int',
    required => 1,
);

has laddr => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has lport => (
    is       => 'ro',
    isa      => 'Int',
    required => 1,
);

has game => (
    is  => 'rw',
    isa => 'Games::Snake',
);

sub _serialize {
    my $self = shift;
    my $p    = $self->game->player;
    return $p->segments;
}

sub _deserialize {
    my ( $self, $input ) = @_;
    my $segments = $input->{payload};
    my $level    = $self->game->level;
    @$segments = map { [ $level->w - $_->[0], $_->[1] ] } @$segments;
    return { segments => $segments };
}

sub handle_remote {
    my ( $self, $wheel, $input ) = @_;

    my $data = $self->_deserialize($input);
    $self->segments( $data->{segments} );

    $wheel->put( { payload => $self->_serialize } );
}

no Mouse;

1;
