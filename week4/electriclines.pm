#!/usr/bin/env perl
use strict;
use warnings;
use Getopt::Long;
use FindBin qw( $Bin );
use lib "$Bin/lib";
use Games::ElectricLines;

my $lines  = 4;
my $exits  = 1;
my $result = GetOptions(
    'lines=i' => \$lines,
    'exits=i' => \$exits,
);
die "See README for usage\n" unless $result;

$lines = 2          if $lines < 2;
$exits = $lines - 1 if $exits >= $lines;
$exits = 1          if $exits < 1;

Games::ElectricLines->new(
    _row_count  => $lines,
    _exit_count => $exits,
)->run();
