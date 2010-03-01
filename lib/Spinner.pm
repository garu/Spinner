package Spinner;
use Carp ();

my $SINGLETON = undef;

sub app { $SINGLETON or Carp::croak "Spinner->new wasn't called yet." }

sub init {
    Carp::croak 'Spinner->init already called. Use Spinner->app' 
        if $SINGLETON;

    # Create our display window
    # This is our actual SDL application window
    $SINGLETON = SDL::Video::set_video_mode( 800, 600, 32,
                    SDL_HWSURFACE | SDL_DOUBLEBUF | SDL_HWACCEL );

    Carp::croak 'Cannot init video mode 800x600x32: ' . SDL::get_error() 
        unless $SINGLETON;

    return $SINGLETON;
}

42;
