package Games::SolarConflict::Controller::MainGame;
use Moose;
use SDL::Event;
use SDL::Events;
use Games::SolarConflict::Roles::Player;
use Games::SolarConflict::Roles::Physical;
use namespace::clean -except => 'meta';

with 'Games::SolarConflict::Roles::Controller';

has players => (
    is => 'ro',
    isa => 'ArrayRef[Games::SolarConflict::Roles::Player]',
);

has sun => (
    is      => 'ro',
    isa     => 'Games::SolarConflict::Sun',
    lazy    => 1,
    builder => '_build_sun',
);

has objects => (
    traits => ['Array'],
    is     => 'ro',
    isa    => 'ArrayRef',
    isa => 'ArrayRef[Games::SolarConflict::Roles::Physical]',
    default => sub          { [] },
    handles => { add_object => 'push' },
);

has controls => (
    is      => 'ro',
    isa     => 'ArrayRef',
    lazy    => 1,
    default => sub {
        [   {   down => {
                    q => sub { $_[0]->_fire_torpedo( $_[1] ) },
                    w => sub { $_[1]->d_a(10) },
                    a => sub { $_[1]->ang_a(-1) },
                    s => sub { $_[0]->_warp_ship( $_[1] ) },
                    d => sub { $_[1]->ang_a(1) },
                },
                up => {
                    w => sub { $_[1]->d_a(0) },
                    a => sub { $_[1]->ang_a(0) },
                    d => sub { $_[1]->ang_a(0) },
                }
            },
            {

                # TODO: reproduce above for player 2
            }
        ];
    },
);

sub _build_sun {
    my ($self) = @_;

    my $sun = $self->game->resolve(
        service    => 'object/sun',
        parameters => {
            x => $self->game->app->w / 2,
            y => $self->game->app->h / 2,
        }
    );
}

around BUILDARGS => sub {
    my ( $orig, $class, %args ) = @_;

    my $game = $args{game};
    my $app  = $game->app;

    my @players = (
        $game->resolve( service => 'object/human_player' ),
        $game->resolve( service => 'object/human_player' )
    );

=pod
    if ( $args{players} == 2 ) {
    }
    else {
    }
=cut

    my $s1 = $players[0]->spaceship;
    $s1->y( $app->h / 2 );
    $s1->x( $app->w / 4 );
    $s1->v_y(-20);
    $s1->ang_v(5);

    my $s2 = $players[1]->spaceship;
    $s2->y( $app->h / 2 );
    $s2->x( 3 * $app->w / 4 );
    $s2->v_y(20);
    $s2->ang_v(5);
    $s2->rotation(180);

    $s1->interface->attach( $app, sub { } );
    $s2->interface->attach( $app, sub { } );

    return $class->$orig( %args, players => \@players );
};

sub BUILD {
    my ($self) = @_;

    $self->add_object( $self->sun );
    $self->add_object( $_->spaceship ) foreach @{ $self->players };

    $_->peers( $self->objects ) foreach @{ $self->objects };
}

sub handle_show {
    my ( $self, $delta, $app ) = @_;

    # TODO: draw background
    $app->draw_rect( [ 0, 0, $app->w, $app->h ], 0x000000FF );

    # TODO: draw power bar for both players

    $_->draw($app) foreach @{ $self->objects };

    $app->update();
}

sub handle_event {
    my ( $self, $event, $app ) = @_;

    if ( $event->type == SDL_QUIT ) {
        $app->stop();
    }
    elsif ( $event->type == SDL_KEYDOWN ) {
        my $key = SDL::Events::get_key_name( $event->key_sym );
        $self->_handle_key( $key, 'down' );
    }
    elsif ( $event->type == SDL_KEYUP ) {
        my $key = SDL::Events::get_key_name( $event->key_sym );
        $self->_handle_key( $key, 'up' );
    }
}

sub handle_move {
    my ( $self, $step, $app, $t ) = @_;

    # TODO: collision detection

    my $w = $app->w;
    my $h = $app->h;

    foreach my $obj ( @{ $self->objects } ) {
        $obj->x( $obj->x - $w ) if $obj->x > $w;
        $obj->x( $obj->x + $w ) if $obj->x < 0;
        $obj->y( $obj->y - $h ) if $obj->y > $h;
        $obj->y( $obj->y + $h ) if $obj->y < 0;
    }
}

sub _handle_key {
    my ( $self, $key, $state ) = @_;

    foreach my $control ( @{ $self->controls } ) {
        if ( defined $control->{$state}{$key} ) {
            $control->{$state}{$key}
                ->( $self, map { $_->spaceship } @{ $self->players } );
        }
    }
}

sub _warp_ship {
    my ( $self, $ship ) = @_;

    $ship->warp( rand( $self->game->app->w ), rand( $self->game->app->h ) );
}

sub _fire_torpedo {
    my ( $self, $ship ) = @_;

    # TODO limit number of torpedos

    my $torpedo = $self->game->resolve( service => 'object/torpedo' );

    $torpedo->interface->attach( $self->game->app, sub { } );
    $torpedo->peers( $self->objects );
    $self->add_object($torpedo);

    $ship->fire_torpedo($torpedo);
}

__PACKAGE__->meta->make_immutable;

1;
