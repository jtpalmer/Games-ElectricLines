package Games::SolarConflict::Controller::MainMenu;
use Mouse;
use SDL::Event;
use SDL::Events;

with 'Games::SolarConflict::Roles::Controller';

sub handle_show {
    my ( $self, $delta, $app ) = @_;

    $app->draw_rect( [ 0, 0, $app->w, $app->h ], 0x000000FF );
    $app->draw_gfx_text( [ 0, 0 ],  0xFFFFFFFF, 'SolarConflict' );
    $app->draw_gfx_text( [ 0, 10 ], 0xFFFFFFFF, 'Press 1 for single player' );
    $app->draw_gfx_text( [ 0, 20 ], 0xFFFFFFFF, 'Press 2 for two player' );

    $app->draw_gfx_text( [ 0, 100 ], 0xFFFFFFFF, 'Player 1' );
    $self->game->spaceship1->sprite->draw_xy( $app, 0, 110 );
    $app->draw_gfx_text( [ 0, 140 ], 0xFFFFFFFF, 'Q - Fire Torpedo' );
    $app->draw_gfx_text( [ 0, 150 ], 0xFFFFFFFF, 'W - Accelerate' );
    $app->draw_gfx_text( [ 0, 160 ], 0xFFFFFFFF, 'A - Rotate CCW' );
    $app->draw_gfx_text( [ 0, 170 ], 0xFFFFFFFF, 'D - Rotate CW' );
    $app->draw_gfx_text( [ 0, 180 ], 0xFFFFFFFF, 'S - Hyperspace' );

    $app->draw_gfx_text( [ 200, 100 ], 0xFFFFFFFF, 'Player 2' );
    $self->game->spaceship2->sprite->draw_xy( $app, 200, 110 );
    $app->draw_gfx_text( [ 200, 140 ], 0xFFFFFFFF, 'U - Fire Torpedo' );
    $app->draw_gfx_text( [ 200, 150 ], 0xFFFFFFFF, 'I - Accelerate' );
    $app->draw_gfx_text( [ 200, 160 ], 0xFFFFFFFF, 'J - Rotate CCW' );
    $app->draw_gfx_text( [ 200, 170 ], 0xFFFFFFFF, 'L - Rotate CW' );
    $app->draw_gfx_text( [ 200, 180 ], 0xFFFFFFFF, 'K - Hyperspace' );
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

no Mouse;

1;
