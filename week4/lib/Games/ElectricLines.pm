package Games::ElectricLines;
use Mouse;
use FindBin qw( $Bin );
use File::Spec;
use SDL;
use SDL::Rect;
use SDLx::App;
use SDLx::Sprite::Animated;

has _share_dir => (
    is      => 'ro',
    isa     => 'Str',
    lazy    => 1,
    default => sub { File::Spec->catdir( $Bin, 'share' ) },
);

has app => (
    is      => 'ro',
    isa     => 'SDLx::App',
    lazy    => 1,
    builder => '_build_app',
    handles => [qw( run )],
);

has sprite => (
    is      => 'ro',
    isa     => 'SDLx::Sprite::Animated',
    lazy    => 1,
    builder => '_build_sprite',
);

sub _build_app {
    return SDLx::App->new(
        title => 'Electric Lines',
        delay => 30,
        eoq   => 1,
    );
}

sub _build_sprite {
    my ($self) = @_;

    my $sprite = SDLx::Sprite::Animated->new(
        rect => SDL::Rect->new( 0, 0, 50, 50 ),
        image => File::Spec->catfile( $self->_share_dir, 'plasma.bmp' ),
        ticks_per_frame => 2,
    );
    $sprite->start();
    return $sprite;
}

sub BUILD {
    my ($self) = @_;

    my $app = $self->app;
    $app->add_event_handler( sub { $self->handle_event(@_) } );
    $app->add_move_handler( sub  { $self->handle_move(@_) } );
    $app->add_show_handler( sub  { $self->handle_show(@_) } );
}

sub handle_event {
    my ( $self, $event, $app ) = @_;
}

sub handle_move {
    my ( $self, $step, $app, $t ) = @_;
}

sub handle_show {
    my ( $self, $delta, $app ) = @_;

    $self->sprite->draw($app);
    $app->update();
}

no Mouse;

1;
