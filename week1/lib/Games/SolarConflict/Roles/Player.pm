package Games::SolarConflict::Roles::Player;
use Moose::Role;

has spaceship => (
    is       => 'ro',
    isa      => 'Games::SolarConflict::Spaceship',
    required => 1,
);

no Moose::Role;

1;
