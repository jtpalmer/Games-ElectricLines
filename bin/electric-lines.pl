#!perl
use strict;
use warnings;
use Getopt::Long;
use Games::ElectricLines;

# PODNAME: electric-lines.pl
# ABSTRACT: Play the game

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

exit;

=pod

=head1 SYNOPSIS

    $ electric-lines.pl

=head1 DESCRIPTION

This script will start the game.

=head1 OPTIONS

=over 4

=item B<--lines>=I<nlines>

Set the number of horizontal lines. Defaults to 4.

=item B<--exits>=I<nexits>

Set the number of exits. Defaults to 1.

=back

=head1 RETURN VALUE

Returns 0 for success

=head1 HOW TO PLAY

Guide the plasma balls to the exits (green circles).  Create new routes
by drawing lines across the horizontal lines using your mouse.

=head1 EXAMPLES

    # Use the default settings.
    $ electic-lines.pl

    # Specify the number of lines and exits.
    $ electic-lines.pl --lines=5 --exits=2

=head1 SEE ALSO

=over 4

=item * L<Games::ElectricLines>

=item * L<SDL>

=back

=cut

