package Games::SolarConflict::Roles::Controller;
use Moose::Role;

has game => (
    is       => 'rw',
    isa      => 'Games::SolarConflict',
    required => 1,
);

no Moose::Role;

1;
