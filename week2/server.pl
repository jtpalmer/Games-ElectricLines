#!/usr/bin/env perl
use strict;
use warnings;
use 5.010;

use Socket;
use Fcntl;
use Getopt::Long;

sub main {
    my $addr;
    my $port = 62174;

    my $result = GetOptions(
        'addr=s' => \$addr,
        'port=i' => \$port,
    );

    my $proto = getprotobyname("udp");

    socket( my $sock, PF_INET, SOCK_DGRAM, $proto )
        or die("socket() failure: $!");

    fcntl( $sock, F_SETFL, O_NONBLOCK | O_RDWR )
        or die("fcntl problem: $!");

    setsockopt( $sock, SOL_SOCKET, SO_REUSEADDR, 1 )
        or die("setsockopt SO_REUSEADDR failed: $!");

    {
        my $addr = inet_aton($addr)
            or die("inet_aton problem: $!");
        my $sockaddr = sockaddr_in( $port, $addr )
            or die("sockaddr_in problem: $!");
        bind( $sock, $sockaddr )
            or die("bind error: $!");
    }

    my $socket = $sock;

    $! = undef;
    while (1) {
        while ( my $a = recv( $socket, my $input = "", 1500, MSG_DONTWAIT ) )
        {
            if ( defined($addr) ) {
                my %input_data;

                if ($a) {
                    my ( $port, $addr ) = unpack_sockaddr_in($a)
                        or warn("sockaddr_in failure: $!");
                    $input_data{addr} = inet_ntoa($addr);
                    $input_data{port} = $port;

                    my $ip = join( '.', unpack( 'CCCC', $addr ) );
                    say "$ip:$port";
                    respond( $sock, $ip, $port );
                }
            }
        }
    }
}

sub respond {
    my ( $sock, $ip, $port ) = @_;

    #my $addr = inet_aton($a)
    #or die("inet_aton problem: $!");
    my $sockaddr = sockaddr_in( $port, pack( 'CCCC', split( /\./, $ip ) ) )
        or die("sockaddr_in problem: $!");

    #connect( $sock, $sockaddr )
    #or die("connect error: $!");

    send( $sock, 42, 0, $sockaddr );
}

main(@ARGV);
