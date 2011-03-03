package Games::SolarConflict::Controller::GameOver;
use Mouse;
use SDL::Event;
use SDL::Events;
use namespace::clean -except => 'meta';

with 'Games::SolarConflict::Roles::Controller';

has players => (
    is       => 'ro',
    isa      => 'Int',
    required => 1,
);

has message => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

sub handle_show {
    my ( $self, $delta, $app ) = @_;

    $app->draw_gfx_text( [ 0, 0 ],  0xFFFFFFFF, $self->message );
    $app->draw_gfx_text( [ 0, 10 ], 0xFFFFFFFF, 'Press R to play again' );
    $app->draw_gfx_text( [ 0, 20 ],
        0xFFFFFFFF, 'Press M to go to the main menu' );
    $app->update();
}

sub handle_event {
    my ( $self, $event, $app ) = @_;

    if ( $event->type == SDL_QUIT ) {
        $app->stop();
    }
    elsif ( $event->type == SDL_KEYDOWN ) {
        my $key = SDL::Events::get_key_name( $event->key_sym );

        if ( $key eq 'r' ) {
            $self->game->transit_to( 'main_game', players => $self->players );
        }
        elsif ( $key eq 'm' ) {
            $self->game->transit_to('main_menu');
        }
    }
}

__PACKAGE__->meta->make_immutable;

1;
