#!/usr/bin/env perl
use strict;
use warnings;
use FindBin qw( $Bin );
use Path::Class;
use lib "$Bin/lib";
use Games::SolarConflict::Container;

my $share = dir( $Bin, 'share' );
my $container = Games::SolarConflict::Container->new( assets => $share );
my $game = $container->resolve( service => 'game' );
$game->run();
