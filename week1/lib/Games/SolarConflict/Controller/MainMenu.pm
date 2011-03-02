package Games::SolarConflict::Controller::MainMenu;
use Moose;
use SDL::Event;
use SDL::Events;
use namespace::clean -except => 'meta';

with 'Games::SolarConflict::Roles::Controller';

sub handle_show {
    my ( $self, $delta, $app ) = @_;

    $app->draw_rect( [ 0, 0, $app->w, $app->h ], 0x000000FF );
    $app->draw_gfx_text( [ 0, 0 ], 0xFFFFFFFF, 'SolarConflict' );
    $app->draw_gfx_text( [ 0, 10 ], 0xFFFFFFFF, 'Press 1 for single player' );
    $app->draw_gfx_text( [ 0, 20 ], 0xFFFFFFFF, 'Press 2 for two player' );
    $app->update();
}

sub handle_event {
    my ( $self, $event, $app ) = @_;

    if ( $event->type == SDL_QUIT ) {
        $app->stop();
    }
    elsif ( $event->type == SDL_KEYDOWN ) {
        my $key = SDL::Events::get_key_name( $event->key_sym );

        if ( $key eq '1' || $key eq '2' ) {
            $self->game->transit_to( 'main_game', players => $key );
        }
    }
}

__PACKAGE__->meta->make_immutable;

1;
