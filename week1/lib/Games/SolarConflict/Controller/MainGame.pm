package Games::SolarConflict::Controller::MainGame;
use Mouse;
use SDL::Event;
use SDL::Events;
use Games::SolarConflict::Roles::Player;
use Games::SolarConflict::Roles::Physical;
use namespace::clean -except => 'meta';

with 'Games::SolarConflict::Roles::Controller';

has players => (
    is       => 'ro',
    isa      => 'Int',
    required => 1,
);

has player1 => (
    is       => 'ro',
    isa      => 'Games::SolarConflict::HumanPlayer',
    required => 1,
);

has player2 => (
    is       => 'ro',
    isa      => 'Games::SolarConflict::Roles::Player',
    required => 1,
);

has background => (
    is       => 'ro',
    isa      => 'SDLx::Surface',
    required => 1,
);

has sun => (
    is      => 'ro',
    isa     => 'Games::SolarConflict::Sun',
    lazy    => 1,
    builder => '_build_sun',
);

has objects => (
    is      => 'ro',
    isa     => 'ArrayRef',
    isa     => 'ArrayRef[Games::SolarConflict::Roles::Physical]',
    default => sub { [] },
);

sub add_object {
    my ( $self, $obj ) = @_;
    push @{ $self->objects }, $obj;
}

has controls => (
    is      => 'ro',
    isa     => 'ArrayRef',
    lazy    => 1,
    default => sub {
        [   {   down => {
                    q => sub { $_[1]->fire_torpedo() },
                    w => sub { $_[1]->d_a(10) },
                    a => sub { $_[1]->ang_a(-5) },
                    s => sub { $_[0]->_warp_ship( $_[1] ) },
                    d => sub { $_[1]->ang_a(5) },
                },
                up => {
                    w => sub { $_[1]->d_a(0) },
                    a => sub { $_[1]->ang_a(0) },
                    d => sub { $_[1]->ang_a(0) },
                },
            },
            {   down => {
                    u => sub { $_[2]->fire_torpedo() },
                    i => sub { $_[2]->d_a(10) },
                    j => sub { $_[2]->ang_a(-5) },
                    k => sub { $_[0]->_warp_ship( $_[2] ) },
                    l => sub { $_[2]->ang_a(5) },
                },
                up => {
                    i => sub { $_[2]->d_a(0) },
                    j => sub { $_[2]->ang_a(0) },
                    l => sub { $_[2]->ang_a(0) },
                },
            },
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

    my $players = $game->get_sub_container('players');

    my $player1
        = $players->create( player => $game->get_sub_container('player1') )
        ->resolve( service => 'human_player' );

    my $player2
        = $players->create( player => $game->get_sub_container('player2') )
        ->resolve( service =>
            ( $args{players} == 1 ? 'computer_player' : 'human_player' ) );

    return $class->$orig( %args, player1 => $player1, player2 => $player2 );
};

sub BUILD {
    my ($self) = @_;

    my $app = $self->game->app;

    my $s1 = $self->player1->spaceship;
    $s1->y( $app->h / 2 );
    $s1->x( $app->w / 4 );
    $s1->v_y(-20);
    $s1->ang_v(5);

    my $s2 = $self->player2->spaceship;
    $s2->y( $app->h / 2 );
    $s2->x( 3 * $app->w / 4 );
    $s2->v_y(20);
    $s2->ang_v(5);
    $s2->rotation(180);

    $s1->interface->attach( $app, sub { } );
    $s2->interface->attach( $app, sub { } );
    $_->interface->attach( $app, sub { } )
        foreach ( @{ $s1->torpedos }, @{ $s2->torpedos } );

    $self->add_object( $self->sun );
    $self->add_object($s1);
    $self->add_object($s2);
    $self->add_object($_) foreach ( @{ $s1->torpedos }, @{ $s2->torpedos } );

    $_->peers( $self->objects ) foreach @{ $self->objects };
}

sub handle_show {
    my ( $self, $delta, $app ) = @_;

    $self->background->blit( $app, [ 0, 0, $app->w, $app->h ] );

    my $p1 = $self->player1->spaceship->power * 3;
    my $p2 = $self->player2->spaceship->power * 3;
    $app->draw_rect( [ 20, $app->h - 40, $p1, 5 ], 0xFFFFFFFF );
    $app->draw_rect( [ -20 + $app->w - $p2, $app->h - 40, $p2, 5 ],
        0xFFFFFFFF );

    $_->draw($app) foreach grep { $_->valid } @{ $self->objects };

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

    foreach my $obj ( @{ $self->objects } ) {
        next unless $obj->valid;
        foreach my $other ( @{ $self->objects } ) {
            next unless $other->valid;
            next if $obj == $other;

            if ( $obj->intersects($other) ) {
                $obj->interact($other);
            }
        }
    }

    my $s1 = $self->player1->spaceship;
    my $s2 = $self->player2->spaceship;
    if ( $s1->power <= 0 && $s2->power <= 0 ) {
        $self->game->transit_to(
            'game_over',
            players => $self->players,
            message => 'Tie Game'
        );
    }
    elsif ( $s1->power <= 0 ) {
        $self->game->transit_to(
            'game_over',
            players => $self->players,
            message => 'Player 2 Wins'
        );
    }
    elsif ( $s2->power <= 0 ) {
        $self->game->transit_to(
            'game_over',
            players => $self->players,
            message => 'Player 1 Wins'
        );
    }

    my $w = $app->w;
    my $h = $app->h;

    foreach my $obj ( @{ $self->objects } ) {
        next unless $obj->valid;
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
            $control->{$state}{$key}->(
                $self, $self->player1->spaceship, $self->player2->spaceship
            );
        }
    }
}

sub _warp_ship {
    my ( $self, $ship ) = @_;

    $ship->warp( rand( $self->game->app->w ), rand( $self->game->app->h ) );
}

__PACKAGE__->meta->make_immutable;

1;
