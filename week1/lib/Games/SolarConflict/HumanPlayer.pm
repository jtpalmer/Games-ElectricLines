package Games::SolarConflict::HumanPlayer;
use Mouse;
use namespace::clean -except => 'meta';

with 'Games::SolarConflict::Roles::Player';

__PACKAGE__->meta->make_immutable;

1;
