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
my $raddr;
my $rport = 62173;
my $saddr = '69.164.218.48';
my $sport = 62174;

my $result = GetOptions(
    'laddr=s' => \$laddr,
    'lport=i' => \$lport,
    'raddr=s' => \$raddr,
    'rport=i' => \$rport,
    'saddr=s' => \$saddr,
    'sport=i' => \$sport,
);

my $game = Games::Snake->new();

my $p2 = Games::Snake::RemotePlayer->new(
    game  => $game,
    size  => $game->size,
    laddr => $laddr,
    lport => $lport,
    saddr => $saddr,
    sport => $sport,
);

if ($raddr) {
    $p2->raddr($raddr);
    $p2->rport($rport);
}

$game->player2($p2);
$game->run($p2);
