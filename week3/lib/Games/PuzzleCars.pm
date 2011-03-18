package Games::PuzzleCars;
use Mouse;
use FindBin qw( $Bin );
use File::Spec;
use SDL;
use SDLx::App;
use Games::PuzzleCars::Map;

has share_dir => (
    is      => 'ro',
    isa     => 'Str',
    default => sub { File::Spec->catdir( $Bin, 'share' ) },
);

has app => (
    is      => 'ro',
    isa     => 'SDLx::App',
    lazy    => 1,
    builder => '_build_app',
    handles => [qw( run )],
);

has difficulty => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has map => (
    is      => 'rw',
    isa     => 'Games::PuzzleCars::Map',
    lazy    => 1,
    builder => '_build_map',
);

sub _build_app {
    return SDLx::App->new(
        w     => 800,
        h     => 600,
        eoq   => 1,
        delay => 100,
    );
}

sub _build_map {
    my $self = shift;
    return Games::PuzzleCars::Map->new(
        w    => $self->app->w,
        h    => $self->app->h,
        file => File::Spec->catfile(
            $self->share_dir, 'maps', $self->{difficulty} . '.txt'
        ),
        roads => {
            w       => 50,
            h       => 50,
            image   => File::Spec->catfile( $self->share_dir, 'roads.bmp' ),
            mapping => [
                [   [ [ 6, 0 ] ],
                    [ [ 2, 0 ], [ 2, 1 ] ],
                    [ [ 4, 0 ], [ 5, 0 ] ],
                    [ [ 0, 0 ] ],
                    [ [ 8, 0 ], [ 8, 1 ], [ 9, 0 ], [ 9, 1 ] ],
                ],
                [   [ [ 7, 0 ] ],
                    [ [ 3, 0 ], [ 3, 1 ] ],
                    [ [ 4, 0 ], [ 5, 0 ] ],
                    [ [ 1, 0 ] ],
                    [ [ 8, 0 ], [ 8, 1 ], [ 9, 0 ], [ 9, 1 ] ],
                ],
                [   [ [ 6, 1 ] ],
                    [ [ 2, 0 ], [ 2, 1 ] ],
                    [ [ 4, 1 ], [ 5, 1 ] ],
                    [ [ 0, 1 ] ],
                    [ [ 8, 0 ], [ 8, 1 ], [ 9, 0 ], [ 9, 1 ] ],
                ],
                [   [ [ 7, 1 ] ],
                    [ [ 3, 0 ], [ 3, 1 ] ],
                    [ [ 4, 1 ], [ 5, 1 ] ],
                    [ [ 1, 1 ] ],
                    [ [ 8, 0 ], [ 8, 1 ], [ 9, 0 ], [ 9, 1 ] ],
                ],
            ],
        },
    );
}

sub BUILD {
    my ($self) = @_;

    my $app = $self->app;
    $app->add_event_handler( sub { $self->handle_event(@_) } );
    $app->add_move_handler( sub  { $self->handle_move(@_) } );
    $app->add_show_handler( sub  { $self->handle_show(@_); } );
}

sub handle_event {
    my ( $self, $event, $app ) = @_;
}

sub handle_move {
    my ( $self, $step, $app, $t ) = @_;
}

sub handle_show {
    my ( $self, $delta, $app ) = @_;

    $self->map->draw($app);
    $app->update();
}

no Mouse;

1;
