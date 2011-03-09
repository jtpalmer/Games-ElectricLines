package Games::Snake;
use Mouse;
use SDL;
use SDL::Event;
use SDLx::App;
use Games::Snake::Player;
use Games::Snake::Level;

has app => (
    is       => 'ro',
    isa      => 'SDLx::App',
    required => 1,
    handles  => [qw( run )],
);

has player => (
    is       => 'ro',
    isa      => 'Games::Snake::Player',
    required => 1,
);

has level => (
    is       => 'ro',
    isa      => 'Games::Snake::Level',
    required => 1,
);

around BUILDARGS => sub {
    my ( $orig, $class ) = @_;

    my $app = SDLx::App->new(
        w   => 800,
        h   => 600,
        eoq => 1,
    );

    my $size = 10;

    my $level = Games::Snake::Level->new(
        size => $size,
        w    => $app->w / $size,
        h    => $app->h / $size,
    );

    my $player = Games::Snake::Player->new(
        size     => $size,
        color    => 0x00FF00FF,
        growing  => 20,
        segments => [ [ 40, 30 ] ],
        direction => [ 1, 0 ],
    );

    return $class->$orig(
        app    => $app,
        player => $player,
        level  => $level,
    );
};

sub BUILD {
    my ($self) = @_;

    my $app = $self->app;
    $app->add_event_handler( sub { $self->handle_event(@_) } );
    $app->add_move_handler( sub  { $self->handle_move(@_) } );
    $app->add_show_handler( sub  { $self->handle_show(@_) } );
}

sub handle_event {
    my ( $self, $event, $app ) = @_;

    my $player = $self->player;

    if ( $event->type == SDL_KEYDOWN ) {
        $player->direction( [ -1, 0 ] )  if $event->key_sym == SDLK_LEFT;
        $player->direction( [ 1,  0 ] )  if $event->key_sym == SDLK_RIGHT;
        $player->direction( [ 0,  -1 ] ) if $event->key_sym == SDLK_UP;
        $player->direction( [ 0,  1 ] )  if $event->key_sym == SDLK_DOWN;
    }
}

sub handle_move {
    my ( $self, $step, $app, $t ) = @_;

    my $level  = $self->level;
    my $player = $self->player;

    $player->move;

    # TODO: Collision detecion
    if ( $player->hit_self() || $level->is_wall( $player->head ) ) {
        $player->alive(0);
    }

    # elsif ( hit apple ){
    #   $self->player->growth( += X )
    # }
}

sub handle_show {
    my ( $self, $delta, $app ) = @_;

    $app->draw_rect( [ 0, 0, $app->w, $app->h ], 0x000000FF );
    $self->level->draw($app);
    $self->player->draw($app);
    $app->update();
}

no Mouse;

1;
