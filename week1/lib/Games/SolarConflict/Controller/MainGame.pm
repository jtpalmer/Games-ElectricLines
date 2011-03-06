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
    is       => 'ro',
    isa      => 'Games::SolarConflict::Sun',
    required => 1,
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
                    a => sub { $_[1]->ang_a(-10) },
                    s => sub { $_[0]->_warp_ship( $_[1] ) },
                    d => sub { $_[1]->ang_a(10) },
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
                    j => sub { $_[2]->ang_a(-10) },
                    k => sub { $_[0]->_warp_ship( $_[2] ) },
                    l => sub { $_[2]->ang_a(10) },
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

around BUILDARGS => sub {
    my ( $orig, $class, %args ) = @_;

    my $game = $args{game};

    my $player1 = $game->get_player( number => 1, type => 'human' );
    my $player2 = $game->get_player(
        number => 2,
        type   => ( $args{players} == 1 ? 'computer' : 'human' )
    );

    return $class->$orig(
        %args,
        background => $game->background,
        sun        => $game->sun,
        player1    => $player1,
        player2    => $player2,
    );
};

sub BUILD {
    my ($self) = @_;

    my $app = $self->game->app;

    my $sun = $self->sun;
    $sun->x( $app->w / 2 );
    $sun->y( $app->h / 2 );

    my $s1 = $self->player1->spaceship;
    $s1->reset();
    $s1->x( $app->w / 4 );
    $s1->y( $app->h / 2 );
    $s1->v_y(-20);
    $s1->ang_v(5);

    my $s2 = $self->player2->spaceship;
    $s2->reset();
    $s2->x( 3 * $app->w / 4 );
    $s2->y( $app->h / 2 );
    $s2->rotation(180);
    $s2->v_y(20);
    $s2->ang_v(5);

    $s1->interface->attach( $app, sub { } );
    $s2->interface->attach( $app, sub { } );
    $_->interface->attach( $app, sub { } )
        foreach ( @{ $s1->torpedos }, @{ $s2->torpedos } );

    $self->add_object($sun);
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
    $p1 = 0 if $p1 < 0;
    $p2 = 0 if $p2 < 0;
    $app->draw_rect( [ 20, $app->h - 40, $p1, 5 ], 0xFFFFFFFF );
    $app->draw_rect( [ -20 + $app->w - $p2, $app->h - 40, $p2, 5 ],
        0xFFFFFFFF );

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

    $self->player2->handle_move( $step, $app, $t ) if $self->players == 1;

    my @active = grep { $_->active } @{ $self->objects };
    my $max = $#active;
    foreach my $obj_id ( 0 .. $max ) {
        my $obj = $active[$obj_id];
        foreach my $other_id ( $obj_id + 1 .. $max ) {
            my $other = $active[$other_id];
            next if $obj == $other;
            if ( $obj->intersects($other) ) {
                $obj->interact($other);
                $other->interact($obj);
            }
        }
    }

    my $s1 = $self->player1->spaceship;
    my $s2 = $self->player2->spaceship;
    if ( !$s1->visible && !$s2->visible ) {
        $self->game->transit_to(
            'game_over',
            players => $self->players,
            message => 'Tie Game'
        );
    }
    elsif ( !$s1->visible ) {
        $self->game->transit_to(
            'game_over',
            players => $self->players,
            message => 'Player 2 Wins'
        );
    }
    elsif ( !$s2->visible ) {
        $self->game->transit_to(
            'game_over',
            players => $self->players,
            message => 'Player 1 Wins'
        );
    }

    my $w = $app->w;
    my $h = $app->h;

    foreach my $obj ( @{ $self->objects } ) {
        next unless $obj->visible;
        $obj->x( $obj->x - $w ) if $obj->x > $w;
        $obj->x( $obj->x + $w ) if $obj->x < 0;
        $obj->y( $obj->y - $h ) if $obj->y > $h;
        $obj->y( $obj->y + $h ) if $obj->y < 0;
    }
}

sub _handle_key {
    my ( $self, $key, $state ) = @_;

    foreach my $control ( @{ $self->controls }[ 0 .. $self->players - 1 ] ) {
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
