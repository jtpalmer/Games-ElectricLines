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
my %_transmit;
my %_setup;

sub run {
    my ( $self, $p2 ) = @_;

    my $ref = refaddr $self;
    $_t{$ref}            = 0.0;
    $_stop{$ref}         = 0;
    $_current_time{$ref} = Time::HiRes::time;
    $_transmit{$ref}     = 0;
    $_setup{$ref}        = 0;

    # TODO: eoq
    $self->add_event_handler( sub { $self->stop() if $_[0]->type == SDL_QUIT }
    );

    POE::Session->create(
        inline_states => {
            _start => sub {
                if ( defined $p2 ) {
                    my $wheel = $_[HEAP]->{udp_wheel} = POE::Wheel::UDP->new(
                        LocalAddr  => $p2->laddr,
                        LocalPort  => $p2->lport,
                        InputEvent => 'udp_input',
                        Filter     => POE::Filter::Stream->new,
                    );
                    $self->add_move_handler(
                        sub { $p2->transmit($wheel) if $_transmit{$ref}; } );
                    $self->add_event_handler(
                        sub {
                            my $key
                                = SDL::Events::get_key_name( $_[0]->key_sym );
                            $_transmit{$ref} = 1
                                if $_[0]->type == SDL_KEYDOWN && $key eq 't';
                        }
                    );
                    $wheel->put(
                        {   payload => ['setup'],
                            addr    => '69.164.218.48',
                            port    => 62174,
                        }
                    );
                }
                else {
                    $_[KERNEL]->yield('run');
                }
            },
            run       => sub { $self->_run(@_); },
            udp_input => sub {
                my $input = $_[ARG0];
                if ( $_setup{$ref} ) {
                    $p2->handle_remote( $_[HEAP]->{udp_wheel}, $input );
                }
                else {
                    $self->_setup( $p2, $input, @_ );
                }
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

    if ( $_stop{$ref} ) {
        delete $_[HEAP]->{udp_wheel};
        exit;
        return;
    }
    else {
        $_[KERNEL]->yield('run');
    }
}

sub stop {
    my $self = shift;
    $_stop{ refaddr $self} = 1;
}

sub _setup {
    my $self   = shift;
    my $player = shift;
    my $input  = shift;

    my $ref = refaddr $self;

    my ( $addr, $port ) = split /:/, $input->{payload}[0];
    $player->raddr($addr);
    $player->rport($port);

    $_setup{$ref}    = 1;
    $_transmit{$ref} = 1;

    $_[KERNEL]->yield('run');
}

sub DESTROY {
    my $self = shift;
    my $ref  = refaddr $self;
    delete $_stop{$ref};
    delete $_t{$ref};
    delete $_current_time{$ref};
    delete $_transmit{$ref};
    delete $_setup{$ref};
}

1;
