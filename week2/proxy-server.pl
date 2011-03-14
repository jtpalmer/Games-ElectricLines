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
    my $saddr;
    my $sport = 62174;
    my $paddr;
    my $pport = 62173;

    my $result = GetOptions(
        'addr=s' => \$addr,
        'saddr=s' => \$saddr,
        'sport=i' => \$sport,
        'paddr=s' => \$paddr,
        'pport=i' => \$pport,
    );

    $paddr ||= $addr;
    $saddr ||= $addr;

    die "IP Address required\n" unless $saddr;

    my $queued = {};
    my %proxied;

    POE::Session->create(
        inline_states => {
            _start => sub {
                $_[HEAP]->{setup_wheel} = POE::Wheel::UDP->new(
                    LocalAddr  => $saddr,
                    LocalPort  => $sport,
                    InputEvent => 'setup_input',
                    Filter     => POE::Filter::Stream->new(),
                );
                $_[HEAP]->{proxy_wheel} = POE::Wheel::UDP->new(
                    LocalAddr  => $paddr,
                    LocalPort  => $pport,
                    InputEvent => 'proxy_input',
                    Filter     => POE::Filter::Stream->new(),
                );
            },
            setup_input => sub {
                my $input = $_[ARG0];

                my $player = join( ':', @$input{qw( addr port )} );
                say $player;
                return unless $input->{payload}[0] eq 'setup';

                $_[HEAP]->{setup_wheel}->put(
                    {   payload => [ "$paddr:$pport" ],
                        addr    => $input->{addr},
                        port    => $input->{port},
                    }
                );

                if (%$queued) {
                    $proxied{$player} = $queued;

                    my $opponent = join( ':', @$queued{qw( addr port )} );
                    $proxied{$opponent} = {
                        addr => $input->{addr},
                        port => $input->{port},
                    };

                    $queued = {};
                    say "$player and $opponent proxied";;
                }
                else {
                    $queued = {
                        addr => $input->{addr},
                        port => $input->{port},
                    };
                }
            },
            proxy_input => sub {
                my $input = $_[ARG0];

                my $player = join( ':', @$input{qw( addr port )} );
                say "recv from $player";

                my $opponent = $proxied{$player};
                return unless $opponent;
                say "send to ", join( ':', @$opponent{qw( addr port )} );

                $_[HEAP]->{proxy_wheel}->put(
                    {   payload => $input->{payload},
                        addr    => $opponent->{addr},
                        port    => $opponent->{port},
                    }
                );
            }
        },
    );

    POE::Kernel->run;
    exit;
}

main(@ARGV);
