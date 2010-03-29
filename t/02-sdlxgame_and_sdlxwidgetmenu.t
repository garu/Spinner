use strict;
use warnings;
use Carp 'croak';
use SDL ;
use SDL::Events ;
use SDL::Video ;
use SDL::Surface;

use lib 'lib';
use SDLx::Game;
use SDLx::Widget::Menu;

croak 'Cannot init  ' . SDL::get_error()
    if SDL::init(SDL_INIT_VIDEO) == -1;

# Create our display window
my $display = SDL::Video::set_video_mode( 800, 600, 32,
                SDL_HWSURFACE | SDL_DOUBLEBUF | SDL_HWACCEL 
           ) or croak 'Cannot create display: ' . SDL::get_error();

my $game = SDLx::Game->new;
my $menu = SDLx::Widget::Menu->new(font => 'data/metro.ttf');
$menu->items(
        'New Game'  => sub {},
        'Load Game' => sub {},
        'Options'   => sub {},
        'Quit'      => sub { $menu->{exit} = 1;  }, #return the of this in event loop
);


$game->add_event_handler( sub { return 0 if $_[0]->type == SDL_QUIT; return 1; } ); #failsafe
$game->add_event_handler( sub { $menu->event_hook($_[0]); return !$menu->{exit};} );
$game->add_show_handler( sub { $menu->render($display); SDL::Video::flip($display); return 1;} );

$game->run;
