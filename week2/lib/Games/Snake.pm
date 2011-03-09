package Games::Snake;
use Mouse;
use SDL;
use SDL::Event;
use SDLx::App;
use Games::Snake::Player;
use Games::Snake::Level;

has app => (
    is      => 'ro',
    isa     => 'SDLx::App',
    lazy    => 1,
    builder => '_build_app',
    handles => [qw( run )],
);

has size => (
    is      => 'ro',
    isa     => 'Int',
    default => 10,
);

has player => (
    is      => 'rw',
    isa     => 'Games::Snake::Player',
    lazy    => 1,
    builder => '_build_player',
);

has level => (
    is      => 'ro',
    isa     => 'Games::Snake::Level',
    lazy    => 1,
    builder => '_build_level',
);

has apple => (
    is      => 'rw',
    isa     => 'ArrayRef',
    lazy    => 1,
    builder => '_build_apple',
);

sub _build_app {
    return SDLx::App->new(
        w   => 800,
        h   => 600,
        eoq => 1,
    );
}

sub _build_level {
    my ($self) = @_;
    return Games::Snake::Level->new(
        size => $self->size,
        w    => $self->app->w / $self->size,
        h    => $self->app->h / $self->size,
    );
}

sub _build_player {
    my ($self) = @_;
    return Games::Snake::Player->new(
        size     => $self->size,
        color    => 0x00FF00FF,
        growing  => 20,
        segments => [ [ 40, 30 ] ],
        direction => [ 1, 0 ],
    );
}

sub _build_apple {
    my ($self) = @_;

    my $level  = $self->level;
    my $player = $self->player;

    my $coord;

    do {
        $coord = [ int( rand( $level->w ) ), int( rand( $level->h ) ) ];
    } while ( $player->is_segment($coord) || $level->is_wall($coord) );

    return $coord;
}

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

        my $key = SDL::Events::get_key_name( $event->key_sym );
        if ( !$player->alive && $key eq 'r' ) {
            $self->player( $self->_build_player );
        }
    }
}

sub handle_move {
    my ( $self, $step, $app, $t ) = @_;

    my $level  = $self->level;
    my $player = $self->player;

    $player->move;

    if ( $player->hit_self() || $level->is_wall( $player->head ) ) {
        $player->alive(0);
    }
    elsif ($player->head->[0] == $self->apple->[0]
        && $player->head->[1] == $self->apple->[1] )
    {
        $player->growing( $player->growing + 10 );
        $self->apple( $self->_build_apple );
    }
}

sub handle_show {
    my ( $self, $delta, $app ) = @_;

    $app->draw_rect( [ 0, 0, $app->w, $app->h ], 0x000000FF );

    my $size = $self->size;
    $app->draw_rect(
        [ ( map { $_ * $size } @{ $self->apple } ), $size, $size ],
        0xFF0000FF );
    $self->level->draw($app);
    $self->player->draw($app);

    $app->draw_gfx_text( [ 12, 12 ], 0xFFFFFFFF, 'Press R to restart' )
        unless $self->player->alive;

    $app->update();
}

no Mouse;

1;
