package Games::SolarConflict::Roles::Controller;
use Mouse::Role;

has game => (
    is       => 'rw',
    isa      => 'Games::SolarConflict',
    required => 1,
);

no Mouse::Role;

1;
