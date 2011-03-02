package Games::SolarConflict::Spaceship;
use Moose;
use Math::Trig qw( deg2rad );
use namespace::clean -except => 'meta';

with 'Games::SolarConflict::Roles::Physical';

has '+mass' => ( default => 100 );

# directional acceleration
has d_a => (
    is      => 'rw',
    isa     => 'Num',
    default => 0,
);

has [qw( shield_power torpedo_power )] => (
    is      => 'rw',
    isa     => 'Num',
    default => 50,
);

has sprite => (
    is      => 'ro',
    isa     => 'Games::SolarConflict::Sprite::Rotatable',
    handles => [qw( draw rect )],
);

with 'Games::SolarConflict::Roles::Drawable';

before draw => sub {
    my ($self) = @_;

    $self->sprite->x( $self->x - $self->rect->w / 2 );
    $self->sprite->y( $self->y - $self->rect->h / 2 );
    $self->sprite->rotation( $self->rotation );
};

after d_a => sub {
    my ( $self, $acc ) = @_;
    $self->_update_acc( $acc, $self->rotation ) if defined $acc;
};

after rotation => sub {
    my ( $self, $rot ) = @_;
    $self->_update_acc( $self->d_a, $rot ) if defined $rot;
};

sub _update_acc {
    my ( $self, $acc, $rot ) = @_;

    my $angle = deg2rad($rot);

    $self->a_x( $acc * sin($angle) );
    $self->a_y( $acc * -cos($angle) );
}

sub power_to_shields {
    my ($self) = @_;

    my $torpedo_power = $self->torpedo_power;
    my $shield_power  = $self->shield_power;

    return unless $torpedo_power > 1 && $shield_power < 100;

    $self->torpedo_power( $torpedo_power - 1 );
    $self->shield_power( $shield_power + 1 );
}

sub power_to_torpedos {
    my ($self) = @_;

    my $torpedo_power = $self->torpedo_power;
    my $shield_power  = $self->shield_power;

    return unless $shield_power > 1 && $torpedo_power < 100;

    $self->shield_power( $shield_power - 1 );
    $self->torpedo_power( $torpedo_power + 1 );
}

sub receive_damage {
    my ( $self, $damage ) = @_;

    $self->shield_power( $self->shield_power - $damage );
}

sub fire_torpedo {
    my ( $self, $torpedo ) = @_;

    my $angle = deg2rad( $self->rotation );
    $torpedo->x( $self->x + sin($angle) * 16 );
    $torpedo->y( $self->y - cos($angle) * 16 );
    $torpedo->v_x( $self->v_x + sin($angle) * 10 );
    $torpedo->v_y( $self->v_y - cos($angle) * 10 );
}

sub laser {
    my ( $self, $status ) = $_;

}

sub warp {
    my ( $self, $x, $y ) = @_;

    # TODO: decrease power?

    $self->x($x);
    $self->y($y);
    $self->v_x(0);
    $self->v_y(0);
    $self->ang_v(0);
}

__PACKAGE__->meta->make_immutable;

1;
