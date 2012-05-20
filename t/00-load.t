#!perl
use strict;
use warnings;
use Test::More;

BEGIN {
    my @modules = qw(
        Games::ElectricLines
    );

    for my $module (@modules) {
        use_ok($module) or BAIL_OUT("Failed to load $module");
    }
}

diag(
    sprintf(
        'Testing Games::ElectricLines %f, Perl %f, %s',
        $Games::ElectricLines::VERSION,
        $], $^X
    )
);

done_testing();

