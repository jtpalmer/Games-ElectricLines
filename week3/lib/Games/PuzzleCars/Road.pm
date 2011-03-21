package Games::PuzzleCars::Road;
use Mouse;

has map => (
    is       => 'ro',
    isa      => 'Games::PuzzleCars::Map',
    #required => 1,
);

has [qw( x y )] => (
    is       => 'ro',
    isa      => 'Int',
    required => 1,
);


has directions => (
    is       => 'ro',
    isa      => 'ArrayRef',
    #required => 1,
);

no Mouse;

1;
