package Spinner;
use strict;
use warnings;

use Carp ();
use JSON::Any;
use SDL;
use SDL::Video;

my $SINGLETON = undef;
my $camera = undef;

sub app { $SINGLETON or Carp::croak "Spinner->new wasn't called yet." }

sub init {
    Carp::croak 'Spinner->init already called. Use Spinner->app' 
        if $SINGLETON;

    # Initing video
    # Die here if we cannot make video init
    Carp::croak 'Cannot init  ' . SDL::get_error()
        if ( SDL::init( SDL_INIT_VIDEO | SDL_INIT_VIDEO ) == -1 );

    my $icon = SDL::Video::load_BMP("data/icon.bmp")
        or Carp::croak SDL::get_error;

    SDL::Video::wm_set_icon($icon);

    # Create our display window
    # This is our actual SDL application window
    $SINGLETON = SDL::Video::set_video_mode( 800, 600, 32,
                    SDL_HWSURFACE | SDL_DOUBLEBUF | SDL_HWACCEL );

    Carp::croak 'Cannot init video mode 800x600x32: ' . SDL::get_error() 
        unless $SINGLETON;
    $camera = SDL::Rect->new(0,0, $SINGLETON->w, $SINGLETON->h);
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

sub write_data_file {
    my ($filename, $data) = @_;
    return unless -r $filename and ref $data;

    my $json = JSON::Any->to_json($data);

    # save it into the file
    open my $fh, '>', $filename
        or Carp::croak "error writing to file '$filename': $!\n";
    print $fh $json;
    close $fh;

    return 1;
}

sub get_camera {
	if(!defined($camera)) {
		die "Spinner::$camera is undefined, dying";
	}
	else {
		return $camera;
	}
}

sub set_camera {
	my ($self, $new_x, $new_y) = @_;
	$camera->x = $new_x;
	$camera->y = $new_y;
}

sub load_image {
    my (undef, $filename, $optimize) = @_;

    my $loaded_img = SDL::Image::load($filename)
        or Carp::croak SDL::get_error;
    return $loaded_img unless $optimize;

    my $opt_img = SDL::Video::display_format($loaded_img)
        or Carp::croak SDL::get_error;
    return $opt_img;
}

42;
