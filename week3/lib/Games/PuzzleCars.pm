package Games::PuzzleCars;
use Mouse;
use FindBin qw( $Bin );
use File::Spec;
use SDL;
use SDLx::App;
use SDLx::Surface;
use Games::PuzzleCars::Map;
use Games::PuzzleCars::Car;

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

has cars => (
    is      => 'ro',
    isa     => 'ArrayRef[Games::PuzzleCars::Car]',
    default => sub { [] },
);

has _car_colors => (
    is      => 'ro',
    isa     => 'ArrayRef[Str]',
    default => sub { [qw( red )] },
);

has _surfaces => (
    is      => 'ro',
    isa     => 'HashRef[SDLx::Surface]',
    default => sub { [] },
    lazy    => 1,
    builder => '_build_surfaces',
);

sub _build_app {
    return SDLx::App->new(
        w     => 800,
        h     => 600,
        dt    => 0.02,
        eoq   => 1,
        delay => 20,
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
        intersection => {
            w     => 40,
            h     => 40,
            image => File::Spec->catfile( $self->share_dir, 'arrows.bmp' ),

        },
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

sub _build_surfaces {
    my ($self) = @_;

    my %surfaces;
    foreach my $color ( @{ $self->_car_colors } ) {
        $surfaces{ $color . '_car' }
            = SDLx::Surface->load(
            File::Spec->catfile( $self->share_dir, 'cars', $color . '.bmp' )
            );
    }

    return \%surfaces;
}

sub BUILD {
    my ($self) = @_;

    push @{ $self->cars },
        Games::PuzzleCars::Car->new(
        rect    => SDL::Rect->new( 0, 0, 34, 34 ),
        surface => $self->_surfaces->{'red_car'},
        map     => $self->map,
        color   => 'red',
        x       => 0,
        y       => 162,
        rot     => 0,
        v_x     => 1,
        v_y     => 0,
        );

    my $app = $self->app;
    $app->add_event_handler( sub { $self->handle_event(@_) } );
    $app->add_move_handler( sub  { $self->handle_move(@_) } );
    $app->add_show_handler( sub  { $self->handle_show(@_); } );
}

sub handle_event {
    my ( $self, $event, $app ) = @_;
    $self->map->handle_event($event);
}

sub handle_move {
    my ( $self, $step, $app, $t ) = @_;
    $_->move( $step, $app, $t ) foreach @{ $self->cars };
}

sub handle_show {
    my ( $self, $delta, $app ) = @_;

    $self->map->draw($app);
    $_->draw($app) foreach @{ $self->cars };
    $app->update();
}

no Mouse;

1;
