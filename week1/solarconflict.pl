#!/usr/bin/env perl
use strict;
use warnings;
use FindBin qw( $Bin );
use Path::Class;
use lib "$Bin/lib";
use Games::SolarConflict;

my $share = dir( $Bin, 'share' );
my $game = Games::SolarConflict->new( assets => $share );
$game->run();
