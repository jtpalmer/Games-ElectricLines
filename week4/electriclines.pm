#!/usr/bin/env perl
use strict;
use warnings;
use 5.010;
use FindBin qw( $Bin );
use lib "$Bin/lib";
use Games::ElectricLines;
Games::ElectricLines->new()->run();
