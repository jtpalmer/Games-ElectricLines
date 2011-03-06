package Games::SolarConflict::ComputerPlayer;
use Mouse;
use namespace::clean -except => 'meta';

with 'Games::SolarConflict::Roles::Player';

has _fire_time => (
    is      => 'rw',
    isa     => 'Num',
    default => 0,
);

sub handle_move {
    my ( $self, $step, $app, $t ) = @_;

    if ( $t > $self->_fire_time + 1 ) {
        $self->spaceship->fire_torpedo();
        $self->_fire_time($t);
    }
}

__PACKAGE__->meta->make_immutable;

1;
