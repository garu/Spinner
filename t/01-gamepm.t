use strict;
use warnings;
use Carp;
use SDL;
use SDL::Video;
use SDL::Surface;
use SDL::Rect;
use SDL::Event;
use SDL::Events;
use Data::Dumper;

use lib 'lib';
use SDLx::Game;

my $app = init();

my $ball = 
{
	x => 0,
	y => 0,
	w => 20,
	h => 20,
	vel => 200,
	x_vel => 0,
	y_vel => 0,

};

sub init {

	# Initing video
	# Die here if we cannot make video init
	croak 'Cannot init  ' . SDL::get_error()  if ( SDL::init( SDL_INIT_VIDEO ) == -1 );


	# Create our display window
	# This is our actual SDL application window
	my $a = SDL::Video::set_video_mode( 800, 600, 32, SDL_HWSURFACE | SDL_DOUBLEBUF | SDL_HWACCEL );

	croak 'Cannot init video mode 800x600x32: ' . SDL::get_error() 
	unless $a;

	return $a;
}



my $game = SDLx::Game->new( event => SDL::Event->new() );

sub on_move {
	my $dt= shift;
	$dt = $dt/1000;
	$ball->{x} += $ball->{x_vel} * $dt;

	$ball->{y} += $ball->{y_vel} * $dt;
	
	return 1;
}

sub on_event {
	my $event = shift;

	while( SDL::Events::poll_event($event) )
	{

		if( $event->type == SDL_KEYDOWN )
		{
			my $key = $event->key_sym;
			$ball->{y_vel} -= $ball->{vel} if $key == SDLK_UP;
			$ball->{y_vel} += $ball->{vel} if $key == SDLK_DOWN;
			$ball->{x_vel} -= $ball->{vel} if $key == SDLK_LEFT;
			$ball->{x_vel} += $ball->{vel} if $key == SDLK_RIGHT;

		}
		elsif ( $event->type == SDL_KEYUP )
		{
			my $key = $event->key_sym;
			$ball->{y_vel} += $ball->{vel} if $key == SDLK_UP;
			$ball->{y_vel} -= $ball->{vel} if $key == SDLK_DOWN;
			$ball->{x_vel} += $ball->{vel} if $key == SDLK_LEFT;
			$ball->{x_vel} -= $ball->{vel} if $key == SDLK_RIGHT;

		}
		elsif ($event->type == SDL_QUIT)
		{
			return 0;
		}

	}

	return 1;
}; 

sub on_show {
        SDL::Video::fill_rect(
            $app,
            SDL::Rect->new(0,0,$app->w, $app->h),
            SDL::Video::map_RGB( $app->format, 0, 0, 0 )
        );

        SDL::Video::fill_rect(
            $app,
            SDL::Rect->new($ball->{x}, $ball->{y}, $ball->{w}, $ball->{h}),
            SDL::Video::map_RGB( $app->format, 0, 0, 255 )
        );

	SDL::Video::flip($app);

	return 0;
};


$game->add_move_handler( \&on_move );
$game->add_event_handler( \&on_event );
$game->add_show_handler( \&on_show );

$game->run();

