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
    my $addr2;
    my $port = 62174;

    my $result = GetOptions(
        'addr=s'  => \$addr,
        'addr2=s' => \$addr2,
        'port=i'  => \$port,
    );

    POE::Session->create(
        inline_states => {
            _start => sub {
                $_[HEAP]->{wheel0} = POE::Wheel::UDP->new(
                    LocalAddr  => $addr,
                    LocalPort  => $port,
                    InputEvent => 'input',
                    Filter     => POE::Filter::Stream->new(),
                );
                $_[HEAP]->{wheel1} = POE::Wheel::UDP->new(
                    LocalAddr  => $addr2,
                    LocalPort  => $port,
                    InputEvent => 'input',
                    Filter     => POE::Filter::Stream->new(),
                );
            },
            input => sub {
                my $input = $_[ARG0];
                say $input->{addr}, ':', $input->{port};
                $_[HEAP]->{wheel1}->put(
                    {   payload => ['Test'],
                        addr    => $input->{addr},
                        port    => $input->{port},
                    }
                );
            },
        },
    );

    POE::Kernel->run;
    exit;
}

main(@ARGV);
