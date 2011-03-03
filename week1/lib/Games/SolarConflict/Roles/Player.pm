package Games::SolarConflict::Roles::Player;
use Mouse::Role;

has spaceship => (
    is       => 'ro',
    isa      => 'Games::SolarConflict::Spaceship',
    required => 1,
);

no Mouse::Role;

1;
