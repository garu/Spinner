package Spinner;
use Carp ();
use JSON::Any;
use SDL::Video;

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

sub load_data_file {
    my $filename = shift;
    return unless -r $filename;

    # load file into $json...
    open my $fh, '<', $filename
        or Carp::croak "error loading file '$filename': $!\n";
    my $json = do { local $/; <$fh> };
    close $fh;

    # ... and then into a hashref
    return JSON::Any->from_json($json);
}

42;
