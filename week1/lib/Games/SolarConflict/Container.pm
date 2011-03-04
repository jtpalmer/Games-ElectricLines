package Games::SolarConflict::Container;
use Moose;
use Bread::Board;
use Path::Class;
use SDLx::App;
use SDL::Rect;
use Games::SolarConflict::Torpedo;
use namespace::clean -except => 'meta';

extends 'Bread::Board::Container';

has assets => (
    is       => 'ro',
    isa      => 'Path::Class::Dir',
    required => 1,
);

sub BUILD {
    my $self = shift;

    container $self => as {

        service game => (
            class        => 'Games::SolarConflict',
            lifecycle    => 'Singleton',
            dependencies => {
                app       => depends_on('/app'),
                container => ( service container => $self ),
            },
        );

        service app => (
            class        => 'SDLx::App',
            lifecycle    => 'Singleton',
            dependencies => {
                w     => ( service w     => 1024 ),
                h     => ( service h     => 768 ),
                title => ( service title => 'SolarConflict' ),
                eoq   => ( service eoq   => 1 ),
            },
        );

        container image => as {
            service background => $self->assets->file('background.bmp');
            service sun        => $self->assets->file('sun.bmp');
        };

        container view => as {
            service background => (
                lifecycle => 'Singleton',
                class     => 'SDLx::Surface',
                block     => sub {
                    my $s = shift;
                    return SDLx::Surface->load( $s->param('image') );
                },
                dependencies => { image => depends_on('/image/background') },
            );
            service sun => (
                class     => 'SDLx::Sprite',
                lifecycle => 'Singleton',
                block     => sub {
                    my $s = shift;
                    my $sun
                        = SDLx::Sprite->new( image => $s->param('image') );
                    $sun->alpha_key(0xFF0000);
                    return $sun;
                },
                dependencies => { image => depends_on('/image/sun') },
            );
        };

        container player1 => as {
            service spaceship_image => $self->assets->file('spaceship1.bmp');
        };

        container player2 => as {
            service spaceship_image => $self->assets->file('spaceship2.bmp');
        };

        container players => ['player'] => as {
            service human_player => (
                class        => 'Games::SolarConflict::HumanPlayer',
                lifecycle    => 'Singleton',
                dependencies => { spaceship => depends_on('spaceship') },
            );
            service computer_player => (
                class        => 'Games::SolarConflict::ComputerPlayer',
                lifecycle    => 'Singleton',
                dependencies => { spaceship => depends_on('spaceship') },
            );
            service spaceship => (
                class     => 'Games::SolarConflict::Spaceship',
                lifecycle => 'Singleton',
                block     => sub {
                    my $s = shift;
                    my @torpedos;
                    push @torpedos, Games::SolarConflict::Torpedo->new()
                        for 1 .. 10;
                    return Games::SolarConflict::Spaceship->new(
                        sprite    => $s->param('sprite'),
                        explosion => $s->param('explosion'),
                        torpedos  => \@torpedos,
                    );
                },
                dependencies => {
                    sprite    => depends_on('spaceship_sprite'),
                    explosion => depends_on('explosion_sprite'),
                },
            );
            service spaceship_sprite => (
                class     => 'Games::SolarConflict::Sprite::Rotatable',
                lifecycle => 'Singleton',
                block     => sub {
                    my $s      = shift;
                    my $sprite = SDLx::Sprite::Animated->new(
                        rect  => $s->param('rect'),
                        image => $s->param('image'),
                    );
                    $sprite->alpha_key(0xFF0000);
                    return Games::SolarConflict::Sprite::Rotatable->new(
                        sprite => $sprite );
                },
                dependencies => {
                    rect =>
                        ( service rect => SDL::Rect->new( 0, 0, 32, 32 ) ),
                    image => depends_on('player/spaceship_image'),
                },
            );
            service explosion_sprite => (
                class => 'SDLx::Sprite::Animated',
                block => sub {
                    my $s         = shift;
                    my $explosion = SDLx::Sprite::Animated->new(
                        image           => $s->param('image'),
                        rect            => $s->param('rect'),
                        max_loops       => 1,
                        ticks_per_frame => 2,
                    );
                    $explosion->alpha_key(0x00FF00);
                    return $explosion;
                },
                dependencies => {
                    image => depends_on('explosion_image'),
                    rect  => depends_on('explosion_rect'),
                },
            );
            service explosion_image => $self->assets->file('explosion.bmp');
            service explosion_rect => SDL::Rect->new( 0, 0, 32, 32 );
        };

        container object => as {
            service sun => (
                class        => 'Games::SolarConflict::Sun',
                lifecycle    => 'Singleton',
                dependencies => { sprite => depends_on('/view/sun') },
                parameters   => {
                    x => { isa => 'Num' },
                    y => { isa => 'Num' },
                },
            );
            service torpedo => ( class => 'Games::SolarConflict::Torpedo' );
        };

        container controller => as {
            service main_menu => (
                class        => 'Games::SolarConflict::Controller::MainMenu',
                lifecycle    => 'Singleton',
                dependencies => { game => depends_on('/game') },
            );
            service main_game => (
                class        => 'Games::SolarConflict::Controller::MainGame',
                dependencies => {
                    game       => depends_on('/game'),
                    background => depends_on('/view/background'),
                },
                parameters => { players => { isa => 'Num' } },
            );
            service game_over => (
                class        => 'Games::SolarConflict::Controller::GameOver',
                lifecycle    => 'Singleton',
                dependencies => { game => depends_on('/game') },
                parameters   => {
                    players => { isa => 'Num' },
                    message => { isa => 'Str' },
                },
            );
        };
    };
}

__PACKAGE__->meta->make_immutable;

1;
