#!/usr/bin/env perl
use strict;
use warnings;
use 5.010;

use POE;
use POE::Wheel::UDP;
use POE::Filter::Stream;
use Getopt::Long;

my $QUEUE = {};

sub main {
    my $addr;
    my $port = 62174;

    my $result = GetOptions(
        'addr=s' => \$addr,
        'port=i' => \$port,
    );

    POE::Session->create(
        inline_states => {
            _start => sub {
                $_[HEAP]->{wheel} = POE::Wheel::UDP->new(
                    LocalAddr  => $addr,
                    LocalPort  => $port,
                    InputEvent => 'input',
                    Filter     => POE::Filter::Stream->new(),
                );
            },
            input => sub {
                my $input = $_[ARG0];
                say $input->{addr}, ':', $input->{port};
                return unless $input->{payload}[0] eq 'setup';
                if (%$QUEUE) {
                    say 'putting';
                    $_[HEAP]->{wheel}->put(
                        {   payload => [ @$QUEUE{qw( addr port )} ],
                            addr    => $input->{addr},
                            port    => $input->{port},
                        }
                    );
                    $_[HEAP]->{wheel}->put(
                        {   payload => [ @$input{qw( addr port )} ],
                            %$QUEUE
                        }
                    );

                    undef $QUEUE;
                }
                else {
                    $QUEUE = {
                        addr => $input->{addr},
                        port => $input->{port},
                    };
                }
            },
        },
    );

    POE::Kernel->run;
    exit;
}

main(@ARGV);
