package Games::SolarConflict;
use Mouse;
use SDLx::App;
use namespace::clean -except => 'meta';

has app => (
    is       => 'ro',
    isa      => 'SDLx::App',
    required => 1,
    handles  => [qw( run )],
);

has container => (
    is       => 'ro',
    isa      => 'Bread::Board::Container',
    required => 1,
    handles  => [qw( resolve get_sub_container )],
);

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
