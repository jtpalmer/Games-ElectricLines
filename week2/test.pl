#!/usr/bin/env perl
use strict;
use warnings;
use 5.010;

use Socket;

my $sock;
my $proto = getprotobyname('udp');
socket( $sock, PF_INET, SOCK_DGRAM, $proto );
my $iaddr = gethostbyname('jtpalmer.net');
my $port  = 62174;
my $sin   = sockaddr_in( $port, $iaddr );

bind( $sock, $sin );

send( $sock, 42, 0, $sin );

my $input;
my $a = recv( $sock, $input, 1500, 0 );

my ( $p, $ad ) = unpack_sockaddr_in($a)
    or warn("sockaddr_in failure: $!");
say join( '.', unpack( 'CCCC', $ad ) ), ':', $p;
say $input;
