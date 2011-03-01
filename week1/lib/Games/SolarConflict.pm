package Games::SolarConflict;
use Moose;
use Bread::Board;
use Path::Class;
use SDLx::App;
use SDL::Rect;
use namespace::clean -except => 'meta';

has app => (
    is      => 'ro',
    isa     => 'SDLx::App',
    lazy    => 1,
    builder => '_build_app',
    handles => [qw( run )],
);

has assets => (
    is       => 'ro',
    isa      => 'Path::Class::Dir',
    required => 1,
);

has _state_map => (
    is      => 'ro',
    lazy    => 1,
    builder => '_build_state_map',
);

has _container => (
    is      => 'ro',
    isa     => 'Bread::Board::Container',
    lazy    => 1,
    builder => '_build_container',
    handles => [qw( resolve )],
);

sub _build_app {
    my ($self) = @_;

    return SDLx::App->new(
        w     => 1024,
        h     => 768,
        title => 'SolarConflict',
        eoq   => 1,
    );
}

sub _build_state_map {
    return {
        start => {
            controller  => 'main_menu',
            transitions => {
                continue => 'main_game',
                abort    => 'end',
            },
        },
        main_game => {
            controller  => 'main_game',
            transitions => {
                game_over => 'game_over',
                abort     => 'end',
            },
        },
        game_over => {
            controller  => 'game_over',
            transitions => {
                start_over => 'main_menu',
                continue   => 'main_game',
                abort      => 'end',
            },
        },
    };
}

sub _build_container {
    my ($self) = @_;

    return container app => as {

        container image => as {
            service sun            => $self->assets->file('sun.bmp');
            service spaceship      => $self->assets->file('spaceship.bmp');
            service spaceship_rect => SDL::Rect->new(0, 0, 32, 32);
        };

        container view => as {
            service spaceship => (
                class        => 'Games::SolarConflict::Sprite::Rotatable',
                dependencies => {
                    image => depends_on('/image/spaceship'),
                    rect  => depends_on('/image/spaceship_rect'),
                },
            );
            service sun => (
                class        => 'SDLx::Sprite',
                dependencies => { image => depends_on('/image/sun') },
            );
        };

        container object => as {
            service human_player => (
                class        => 'Games::SolarConflict::HumanPlayer',
                dependencies => { spaceship => depends_on('spaceship') },
            );
            service computer_player => (
                class        => 'Games::SolarConflict::ComputerPlayer',
                dependencies => { spaceship => depends_on('spaceship') },
            );
            service spaceship => (
                class        => 'Games::SolarConflict::Spaceship',
                dependencies => { sprite => depends_on('/view/spaceship') },
            );
            service sun => (
                class        => 'Games::SolarConflict::Sun',
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
                dependencies => { game => ( service game => $self ) },
            );
            service main_game => (
                class        => 'Games::SolarConflict::Controller::MainGame',
                dependencies => { game => ( service game => $self ) },
            );
            service game_over => (
                class        => 'Games::SolarConflict::Controller::GameOver',
                dependencies => { game => ( service game => $self ) },
            );
        };
    };
}

sub BUILD {
    my ($self) = @_;

    $self->transit_to('main_menu');
}

sub transit_to {
    my ( $self, $state, %params ) = @_;

    my $app = $self->app;

    $app->remove_all_handlers();

    my $controller = $self->resolve(
        service    => "controller/$state",
        parameters => \%params,
    );

    $app->add_event_handler( sub { $controller->handle_event(@_) } )
        if $controller->can('handle_event');

    $app->add_move_handler( sub { $controller->handle_move(@_) } )
        if $controller->can('handle_move');

    $app->add_show_handler( sub { $controller->handle_show(@_) } )
        if $controller->can('handle_show');
}

__PACKAGE__->meta->make_immutable;

1;
