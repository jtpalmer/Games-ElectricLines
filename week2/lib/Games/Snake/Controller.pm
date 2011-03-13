package Games::Snake::Controller;
use strict;
use warnings;
use parent qw( SDLx::Controller );
use Scalar::Util qw( refaddr );
use POE;
use POE::Wheel::UDP;
use POE::Filter::Stream;
use SDL::Event;
use SDL::Events;

my %_stop;
my %_t;
my %_current_time;

sub run {
    my ($self, $p2) = @_;

    my $ref = refaddr $self;
    $_t{$ref}            = 0.0;
    $_stop{$ref}         = 0;
    $_current_time{$ref} = Time::HiRes::time;

    # TODO: eoq
    $self->add_event_handler( sub { $self->stop() if $_[0]->type == SDL_QUIT }
    );

    my $wheel;
    if (defined $p2) {
        $wheel = POE::Wheel::UDP->new(
                LocalAddr  => $p2->laddr,
                LocalPort  => $p2->lport,
                PeerAddr   => $p2->raddr,
                PeerPort   => $p2->rport,
                InputEvent => 'udp_input',
                Filter     => POE::Filter::Stream->new,
        );
    }

    POE::Session->create(
        inline_states => {
            _start => sub {
                $_[HEAP]->{udp_wheel} = $wheel if defined $wheel;
                $_[KERNEL]->yield('run');
            },
            run    => sub { $self->_run(@_); },
            udp_input => sub {
                my $input = $_[ARG0];
                $p2->handle_remote( $_[HEAP]->{udp_wheel}, $input );
            },
        },
    );

    POE::Kernel->run();
    exit;
}

sub _run {
    my $self = shift;

    my $ref   = refaddr $self;
    my $dt    = $self->dt;
    my $min_t = $self->min_t;

    $self->_event($ref);

    my $new_time   = Time::HiRes::time;
    my $delta_time = $new_time - $_current_time{$ref};

    $_[KERNEL]->yield('run') if $delta_time < $min_t;

    $_current_time{$ref} = $new_time;
    my $delta_copy = $delta_time;

    while ( $delta_copy > $dt ) {
        $self->_move( $ref, 1, $_t{$ref} );    #a full move
        $delta_copy -= $dt;
        $_t{$ref} += $dt;
    }
    my $step = $delta_copy / $dt;
    $self->_move( $ref, $step, $_t{$ref} );    #a partial move
    $_t{$ref} += $dt * $step;

    $self->_show( $ref, $delta_time );

    # TODO: delay
    SDL::delay(20);

    $_[KERNEL]->yield('run') unless $_stop{$ref};
}

sub stop {
    my $self = shift;
    $_stop{ refaddr $self} = 1;
}

sub DESTROY {
    my $self = shift;
    my $ref  = refaddr $self;
    delete $_stop{$ref};
    delete $_t{$ref};
    delete $_current_time{$ref};
}

1;
