#!/usr/bin/env perl
use strict;
use warnings;
use 5.010;

use POE;
use POE::Wheel::UDP;
use POE::Filter::Stream;
use Getopt::Long;

sub main {
    my $addr;
    my $port = 62174;

    my $result = GetOptions(
        'addr=s' => \$addr,
        'port=i' => \$port,
    );

    my $queued = {};

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
                if (%$queued) {
                    say 'putting';
                    $_[HEAP]->{wheel}->put(
                        {   payload =>
                                [ join( ':', @$queued{qw( addr port )} ) ],
                            addr => $input->{addr},
                            port => $input->{port},
                        }
                    );
                    $_[HEAP]->{wheel}->put(
                        {   payload =>
                                [ join( ':', @$input{qw( addr port )} ) ],
                            %$queued
                        }
                    );

                    $queued = {};
                }
                else {
                    $queued = {
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
