#!/usr/bin/env perl
use strict;
use warnings;
use FindBin qw( $Bin );
use lib "$Bin/lib";
use Games::Snake;
use Games::Snake::RemotePlayer;
use Getopt::Long;
use Net::Address::IP::Local;

my $laddr = Net::Address::IP::Local->public_ipv4;
my $lport = 62173;

my $result = GetOptions(
    'laddr=s' => \$laddr,
    'lport=i' => \$lport,
);

my $game = Games::Snake->new();

my $p2 = Games::Snake::RemotePlayer->new(
    game  => $game,
    size  => $game->size,
    laddr => $laddr,
    lport => $lport,
);

$game->player2($p2);
$game->run($p2);
