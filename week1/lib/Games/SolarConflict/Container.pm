package Games::SolarConflict::Container;
use Mouse::Role;
use SDL::Rect;
use SDLx::App;
use SDLx::Surface;
use SDLx::Sprite;
use SDLx::Sprite::Animated;
use Games::SolarConflict;
use Games::SolarConflict::Sprite::Rotatable;
use Games::SolarConflict::Sun;
use Games::SolarConflict::Spaceship;
use Games::SolarConflict::Torpedo;
use Games::SolarConflict::HumanPlayer;
use Games::SolarConflict::Controller::MainMenu;
use Games::SolarConflict::Controller::MainGame;
use Games::SolarConflict::Controller::GameOver;

has app => (
    is       => 'ro',
    isa      => 'SDLx::App',
    required => 1,
    handles  => [qw( run )],
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

has spaceship1 => (
    is       => 'ro',
    isa      => 'Games::SolarConflict::Spaceship',
    required => 1,
);

has spaceship2 => (
    is       => 'ro',
    isa      => 'Games::SolarConflict::Spaceship',
    required => 1,
);

has _controllers => (
    is      => 'ro',
    isa     => 'HashRef',
    lazy    => 1,
    builder => '_build_controllers',
);

sub _build_controllers {
    my ($self) = @_;

    return {
        main_menu => sub {
            my (%args) = @_;
            return Games::SolarConflict::Controller::MainMenu->new(%args);
        },
        main_game => sub {
            my (%args) = @_;
            return Games::SolarConflict::Controller::MainGame->new(
                %args,
                background => $self->background,
                sun        => $self->sun,
            );
        },
        game_over => sub {
            my (%args) = @_;
            return Games::SolarConflict::Controller::GameOver->new(%args);
        },
    };
}

around BUILDARGS => sub {
    my ( $orig, $class, %args ) = @_;

    my $app = SDLx::App->new(
        w     => 1024,
        h     => 768,
        title => 'SolarConflict',
        eoq   => 1,
    );

    my $assets = $args{assets};

    my %file = (
        background => $assets->file('background.bmp'),
        sun        => $assets->file('sun.bmp'),
        spaceship1 => $assets->file('spaceship1.bmp'),
        spaceship2 => $assets->file('spaceship2.bmp'),
        explosion  => $assets->file('explosion.bmp'),
    );

    my %view = (
        background => SDLx::Surface->load( $file{background} ),
        sun        => SDLx::Sprite->new( image => $file{sun} ),
        spaceship1 => Games::SolarConflict::Sprite::Rotatable->new(
            sprite => SDLx::Sprite::Animated->new(
                rect  => SDL::Rect->new( 0, 0, 32, 32 ),
                image => $file{spaceship1},
            ),
        ),
        spaceship2 => Games::SolarConflict::Sprite::Rotatable->new(
            sprite => SDLx::Sprite::Animated->new(
                rect  => SDL::Rect->new( 0, 0, 32, 32 ),
                image => $file{spaceship2},
            ),
        ),
        explosion => SDLx::Sprite::Animated->new(
            rect            => SDL::Rect->new( 0, 0, 32, 32 ),
            image           => $file{explosion},
            max_loops       => 1,
            ticks_per_frame => 2,
        ),
    );

    $view{sun}->alpha_key(0xFF0000);
    $view{spaceship1}->alpha_key(0xFF0000);
    $view{spaceship2}->alpha_key(0xFF0000);
    $view{explosion}->alpha_key(0x00FF00);

    my @torpedos1 = map { Games::SolarConflict::Torpedo->new() } 1 .. 10;
    my @torpedos2 = map { Games::SolarConflict::Torpedo->new() } 1 .. 10;

    my %objects = (
        app        => $app,
        background => $view{background},
        sun        => Games::SolarConflict::Sun->new( sprite => $view{sun} ),
        spaceship1 => Games::SolarConflict::Spaceship->new(
            sprite    => $view{spaceship1},
            explosion => $view{explosion},
            torpedos  => \@torpedos1,
        ),
        spaceship2 => Games::SolarConflict::Spaceship->new(
            sprite    => $view{spaceship2},
            explosion => $view{explosion},
            torpedos  => \@torpedos2,
        ),
    );

    return $class->$orig( %args, %objects );
};

sub get_controller {
    my ( $self, $name, %args ) = @_;

    return $self->_controllers->{$name}->( %args, game => $self );
}

sub get_player {
    my ( $self, %args ) = @_;

    my $spaceship = 'spaceship' . $args{number};

    return Games::SolarConflict::HumanPlayer->new(
        spaceship => $self->$spaceship, );
}

no Mouse::Role;

1;
