use strict;
use warnings;
use Carp;
use SDL;
use SDL::Video;
use SDL::Surface;

use SDL::Event;
use SDL::Events;


use lib 'lib';
use SDLx::Game;

my $app = init();

my $ball = 
{
   x => 0,
   y => 0,
   w => 120,
   h => 120,
   vel => 200,
   x_vel => 0,
   y_vel => 0,
   event => SDL::Event->new()

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

$game->on_move( \&move );
$game->on_event( \&event );

$game->run();
sub move
{
  my $delta_time = shift;

  carp 'Move';

  return 1;
}

sub event
{
   my $event = shift;
   while( SDL::Events::poll_event($event) )
   {
	 warn 'Event: '.$event->type;
	return 0 if $event->type == SDL_QUIT

   }

   return 1;
} 

sub show
{


}






