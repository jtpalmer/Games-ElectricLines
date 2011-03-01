package Games::SolarConflict::Roles::Physical;
use Moose::Role;
use SDLx::Controller::Interface;
use SDLx::Controller::State;
use Math::Trig;

# Acceleration produced by object on itself
has [qw( a_x a_y ang_a )] => (
    is      => 'rw',
    isa     => 'Num',
    default => 0,
);

has mass => (
    is      => 'rw',
    isa     => 'Num',
    default => 1,
);

has interface => (
    is       => 'ro',
    isa      => 'SDLx::Controller::Interface',
    required => 1,
);

has state => (
    is      => 'rw',
    isa     => 'SDLx::Controller::State',
    lazy    => 1,
    handles => [qw( x y rotation v_x v_y ang_v )],
    default => sub { $_[0]->interface->current },
);

has peers => (
    is      => 'rw',
    isa     => 'ArrayRef',
    isa     => 'ArrayRef[Games::SolarConflict::Roles::Physical]',
    default => sub { [] },
);

around BUILDARGS => sub {
    my ( $orig, $class, %args ) = @_;

    my $interface = SDLx::Controller::Interface->new(
        x     => $args{x},
        y     => $args{y},
        v_x   => $args{v_x},
        v_y   => $args{v_y},
        rot   => $args{rot},
        ang_v => $args{ang_v},
    );

    return $class->$orig( %args, interface => $interface, );
};

sub BUILD {}

after BUILD => sub {
    my ($self) = @_;

    $self->interface->set_acceleration( sub { $self->acc(@_) } );
};

sub force_on {
    my ( $self, $obj ) = @_;

    my $f = $self->mass * $obj->mass / $self->distance_from($obj);
    return ( $f * ($self->x - $obj->x), $f * ($self->y - $obj->y));
}

sub distance_from {
    my ( $self, $obj ) = @_;

    my $dx = $self->x - $obj->x;
    my $dy = $self->y - $obj->y;
    return sqrt( $dx * $dx + $dy * $dy );
}

sub acc {
    my ( $self, $time, $state ) = @_;

    my ( $a_x, $a_y, $ang_a ) = ( $self->a_x, $self->a_y, $self->ang_a );

    foreach my $peer ( @{ $self->peers } ) {
        next if $peer == $self;

        my ( $f_x, $f_y ) = $peer->force_on($self);
        $a_x += $f_x / $self->mass;
        $a_y += $f_y / $self->mass;
    }

    return ( $a_x, $a_y, $ang_a );
}

no Moose::Role;

1;
