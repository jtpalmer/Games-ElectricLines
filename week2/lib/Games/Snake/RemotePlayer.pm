package Games::Snake::RemotePlayer;
use Mouse;
use JSON qw( to_json from_json );

extends 'Games::Snake::Player';

has '+size'  => ( default => 1 );
has '+color' => ( default => 0xE8E623FF );

# Local player
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

# Remote player
has raddr => (
    is  => 'rw',
    isa => 'Str',
);

has rport => (
    is  => 'rw',
    isa => 'Int',
);

# Server
has saddr => (
    is  => 'rw',
    isa => 'Str',
);

has sport => (
    is  => 'rw',
    isa => 'Int',
);

has game => (
    is  => 'rw',
    isa => 'Games::Snake',
);

sub _serialize {
    my $self = shift;
    my $p    = $self->game->player;
    return [ to_json( $p->segments ) ];
}

sub _deserialize {
    my ( $self, $input ) = @_;
    my $segments = from_json( $input->{payload}[0] );
    my $level    = $self->game->level;
    @$segments = map { [ $level->w - $_->[0], $_->[1] ] } @$segments;
    return { segments => $segments };
}

sub handle_remote {
    my ( $self, $wheel, $input ) = @_;

    my $data = eval { $self->_deserialize($input) };
    return if $@;

    @{ $self->segments } = @{ $data->{segments} };

    # Update remote port, just in case it changed
    $self->rport( $input->{port} );

    return;
}

sub transmit {
    my ( $self, $wheel ) = @_;
    $wheel->put(
        {   payload => $self->_serialize,
            addr    => $self->raddr,
            port    => $self->rport,
        }
    );
    return;
}

no Mouse;

1;
