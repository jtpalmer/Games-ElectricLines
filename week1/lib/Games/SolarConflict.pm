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

has _container => (
    is      => 'ro',
    isa     => 'Bread::Board::Container',
    lazy    => 1,
    builder => '_build_container',
    handles => [qw( resolve get_sub_container )],
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

sub _build_container {
    my ($self) = @_;

    return container app => as {

        container image => as {
            service sun => $self->assets->file('sun.bmp');
        };

        container view => as {
            service sun => (
                class        => 'SDLx::Sprite',
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
                dependencies => { spaceship => depends_on('spaceship') },
            );
            service computer_player => (
                class        => 'Games::SolarConflict::ComputerPlayer',
                dependencies => { spaceship => depends_on('spaceship') },
            );
            service spaceship => (
                class        => 'Games::SolarConflict::Spaceship',
                dependencies => { sprite => depends_on('spaceship_sprite') },
            );
            service spaceship_sprite => (
                class => 'Games::SolarConflict::Sprite::Rotatable',
                block => sub {
                    my $s = shift;
                    my $sprite = SDLx::Sprite::Animated->new(
                        rect  => $s->param('rect'),
                        image => $s->param('image'),
                    );
                    $sprite->alpha_key(0xFF0000);
                    return Games::SolarConflict::Sprite::Rotatable->new(
                        sprite => $sprite,
                    );
                },
                dependencies => {
                    rect =>
                        ( service rect => SDL::Rect->new( 0, 0, 32, 32 ) ),
                    image => depends_on('player/spaceship_image'),
                },
            );
        };

        container object => as {
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
                parameters   => { players => { isa => 'Num' } },
            );
            service game_over => (
                class        => 'Games::SolarConflict::Controller::GameOver',
                dependencies => { game => ( service game => $self ) },
                parameters   => {
                    players => { isa => 'Num' },
                    message => { isa => 'Str' },
                },
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
