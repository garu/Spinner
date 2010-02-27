#!/usr/bin/perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/lib";
use Spinner::Ball;
use Spinner::Level;

use SDL;
use SDL::Video;
use SDL::Surface;
use SDL::Rect;
use SDL::Events;
use SDL::Event;
use SDL::Time;
use SDL::Color;
use SDL::GFX::Primitives;
use SDL::Image;

use SDL::Mixer;
use SDL::Mixer::Music;
use SDL::Mixer::Channels;
use SDL::Mixer::Samples;
use SDL::Mixer::MixChunk;

use Data::Dumper;
use Carp;
my $DEBUG = 0;

#Initing video
#Die here if we cannot make video init
croak 'Cannot init  ' . SDL::get_error()
  if ( SDL::init( SDL_INIT_VIDEO | SDL_INIT_VIDEO ) == -1 );

SDL::Mixer::open_audio( 44100, AUDIO_S16, 2, 4096 );

 my ($status, $freq, $format, $channels) = @{ SDL::Mixer::query_spec() };

 my $audiospec = sprintf("%s, %s, %s, %s\n", $status, $freq, $format, $channels);
 
 print  ' Asked for freq, format, channels ', join( ' ', ( 44100, AUDIO_S16, 2,) );
 print  ' Got back status,  freq, format, channels ', join( ' ', ( $status, $freq, $format, $channels ) );


#pre-load the effects

my $grab_chunk  = SDL::Mixer::Samples::load_WAV('data/grab.ogg');
my $bounce_chunk = SDL::Mixer::Samples::load_WAV('data/bounce.ogg');
my $menu_sel_chunk =  SDL::Mixer::Samples::load_WAV('data/menu_select.ogg');
my $music = SDL::Mixer::Music::load_MUS('data/bg.ogg');

die 'Music not found: ' . SDL::get_error() if !$music;

#only play music if our status indicates we go the capability
if ($status == 1) { SDL::Mixer::Music::play_music( $music, -1 ); };

SDL::Mixer::Music::volume_music(15);

SDL::Video::wm_set_icon(SDL::Video::load_BMP("data/icon.bmp"));


#Make our display window
#This is our actual SDL application window
my $app = SDL::Video::set_video_mode( 800, 600, 32,
    SDL_HWSURFACE | SDL_DOUBLEBUF | SDL_HWACCEL );

croak 'Cannot init video mode 800x600x32: ' . SDL::get_error() if !($app);

#Some global variables used thorugh out the game
my $app_rect = SDL::Rect->new( 0, 0, 800, 600 );
my $fps = 30;

# The surface of the background
my $bg_surf = init_bg_surf($app);

my $ball_image = SDL::Image::load('data/ball.png');
my $spinner_menu = SDL::Image::load('data/main.png');

SDL::Video::wm_set_caption( 'Spinner', 'spinner' );


my $quit  = 0;
my $score = 0;

menu();

SDL::Mixer::close_audio();

sub menu {
    my $choice  = 0;
    my @choices = ( 'New Game', 'Quit' );
    my $event   = SDL::Event->new();
    my $menu_quit = 0;
    while ( !$menu_quit ) {
        while ( SDL::Events::poll_event($event) )
        {    #Get all events from the event queue in our event

            #If we have a quit event i.e click on [X] trigger the quit flage
            if ( $event->type == SDL_QUIT ) {
                $menu_quit = 1;
            }
            elsif ( $event->type == SDL_KEYDOWN ) {

                $menu_quit = 1 if $event->key_sym == SDLK_ESCAPE;
                SDL::Video::wm_toggle_fullscreen($app)
                  if $event->key_sym == SDLK_f;

                if ( $event->key_sym == SDLK_DOWN ) {
                    $choice++;
		    handle_chunk($menu_sel_chunk); 

                    $choice = 0 if $choice > $#choices;
                }

                if ( $event->key_sym == SDLK_UP ) {
                    $choice--;
		   handle_chunk($menu_sel_chunk); 

                    $choice = $#choices if $choice < 0;
                }

                if (   $event->key_sym == (SDLK_RETURN)
                    || $event->key_sym == (SDLK_KP_ENTER) )
                {

               #proally better to do this with a hash that holds the sub but meh

                    game() if $choice == 0;
                    $menu_quit = 1 if $choice == 1;

                }

            }

        }

         SDL::Video::fill_rect( $app, $app_rect,
            SDL::Video::map_RGB( $app->format, 0, 0, 0 ) );
    
        # Blit the back ground surface to the window
        SDL::Video::blit_surface(
            $bg_surf, SDL::Rect->new( 0, 0, $bg_surf->w, $bg_surf->h ),
            $app,     SDL::Rect->new( 0, 0, $app->w,     $app->h )
        );

         SDL::Video::blit_surface(
            $spinner_menu, SDL::Rect->new( 0, 0, $spinner_menu->w, $spinner_menu->h ),
            $app,     SDL::Rect->new( 0, 0, $app->w,     $app->h )
        );
        my $h = 100;
        foreach (@choices) {
           my $str = $_;
            my $color = 0x00CC34DD;
            $color = 0xFF0000FF if $choices[$choice] =~ /$_/;
            SDL::GFX::Primitives::string_color( $app, $app->w / 2 - 70,
                $h += 50, $str, $color );
        }

        SDL::Video::flip($app);
    }

}

sub game {
    $quit = 0;
    my $level = Spinner::Level->new;
    $score = 0;
    while ( $level->load($app) ) {
        my $finished = play($level);
        last if $quit or not $finished;
        $level->number( $level->number + 1 );
        $score += 1000;
    }
    
    

}

# create the given level. returns true if level is over,
# or false if player died.
sub play {
    my $level = shift;

    
    my $particles_left = scalar @{$level->wheels};

    # start the ball in a random wheel
    my $ball = Spinner::Ball->new( n_wheel => int rand $particles_left);
    $ball->surface( $ball_image );

    # Get an event object to snapshot the SDL event queue
    my $event = SDL::Event->new();

    # SDL time is recorded in ticks,
    # Ticks are the  milliseconds since the SDL library was loaded into memory
    my $time = SDL::get_ticks();

    # This is our level continue flag
    my $cont = 1;

    # Init some level globals for time calculations
    my ( $dt, $t, $accumulator, $cur_time ) = ( 0.001, 0, 0, SDL::get_ticks() );

    #Keep a copy of the cur_time for Frames per Rate calculations
    my $init_time = $cur_time;

    #Keep a count of number of frames
    my $frames = 0;

    #Our level game loop
    while ( $cont && !$quit ) {

        while ( SDL::Events::poll_event($event) )
        {    #Get all events from the event queue in our event

            #If we have a quit event i.e click on [X] trigger the quit flage
            if ( $event->type == SDL_QUIT ) {
                $quit = 1;
            }
            elsif ( $event->type == SDL_KEYDOWN ) {
                $particles_left =
                  check_ball_release( $ball, $level->wheels, $particles_left )
                  if $event->key_sym == SDLK_SPACE;
                $quit = 1 if $event->key_sym == SDLK_ESCAPE;
                SDL::Video::wm_toggle_fullscreen($app)
                  if $event->key_sym == SDLK_f;
                  
                  if ( $event->key_sym == SDLK_LEFT ) {
                    $ball->rotating(1);
                }

                if ( $event->key_sym == SDLK_RIGHT ) {
                    $ball->rotating(-1);
                }
            }
            elsif ( $event->type == SDL_KEYUP )
            {
                $ball->rotating(0);
            }
            warn 'event' if $DEBUG;

        }

        warn 'level' if $DEBUG;

        #Get a new time for use now
        my $new_time = SDL::get_ticks();

        #Check out how much time we have lost in calculations
        my $delta_time = $new_time - $cur_time;

        #if our delta_time is too fast we can skip this time
        #or we will have jitters in our animation
        next if ( $delta_time <= 0.0 );

        #set our new cur_time for the next calulation of delta time
        $cur_time = $new_time;

       #accumulate our delta_time. This is like our queue for back log animation
        $accumulator += $delta_time;

        # release the time in $dt amount of time so we have smooth animations
        while ( $accumulator >= $dt && !$quit ) {

            # update our particle locations base on dt time
            # (x,y) = dv*dt
            ######iterate_step($dt);
           my $effect = $ball->update( $dt, $level->wheels, $app );
           
           
           handle_chunk($bounce_chunk) if $effect == 1;
           
           handle_chunk($grab_chunk) if $effect == 2;

            # losing condition
            if ( $ball->n_wheel >= 0 and $level->wheels->[ $ball->n_wheel ]->visited ) {
                SDL::GFX::Primitives::string_color(
                    $app,
                    $app->w / 2 - 150,
                    $app->h / 2 - 4,
                    "YOU LOSE!!! Score: $score", 0x00FF00FF
                );
                SDL::Video::flip($app);
                SDL::delay(1000);
                $quit = 1;
            }

            #dequeue our time accumulator
            $accumulator -= $dt;

            #update how much real time we have animated
            $t += $dt;
            warn 'acc' if $DEBUG;
        }

        #Checkout our frames per seconds
        my $fps = $frames / ( ( SDL::get_ticks() - $init_time ) / 1000 );

        #If we are updating too fast we slow down
        #This way the X Draws don't kill our user's computer
        while ( $fps > 30 && !$quit ) {
            $fps = $frames / ( ( SDL::get_ticks() - $init_time ) / 1000 );
            SDL::delay(10);
            warn 'fps' if $DEBUG;
        }

        #If our fps starts to suffer we update our $dt,
        #this way more movement for less time
        if ( $fps < ( 30 - $dt ) ) {
            $dt += ( 30 - $fps ) * 0.1;
        }

        #Update our view and count our frames
        draw_to_screen( $fps, $level, $app, $ball, $level->wheels,
            $particles_left );

        $frames++;

        # Check if we have won this level!
        $cont = check_win( $init_time, $particles_left, $app );
    }
    return !$quit;
}

# Create a background surface once so we
# Can keep using it as many times as we need
sub init_bg_surf {
    my $app = shift;
    my $bg = SDL::Image::load('data/bg.png');
    return $bg;
}

# Check if we are done this level
sub check_win {
    my $init_time      = shift;
    my $particles_left = shift;
    my $app            = shift;

    if ( $particles_left <= 0 ) {
        my $secs_to_win = ( SDL::get_ticks() - $init_time / 1000 );
        my $str =
          sprintf( "Level completed in : %2d millisecs !!!", $secs_to_win );
        SDL::GFX::Primitives::string_color(
            $app,
            $app->w / 2 - 150,
            $app->h / 2 - 4,
            $str, 0x00FF00FF
        );

        SDL::Video::flip($app);
        SDL::delay(1000);
        return 0;
    }
    return 1;
}

# Release ball from wheel (if possible)
# FIXME: we return the number of particles left
# which is silly
sub check_ball_release {
    
    
    my ( $ball, $particles, $particles_left ) = @_;
   # warn $ball->ready;
    return  $particles_left if ! $ball->ready; #the ball is not ready to release yet 
    # we can't release the ball if it isn't attached to a wheel
    return $particles_left if $ball->n_wheel == -1;

    my $w = $particles->[ $ball->n_wheel ];

    if ( !$w->visited ) {

        # change wheel color so player knows it's touched
        $w->color(0x111111FF);
        $w->init_surface($app);

        $w->visited(1);
        $particles_left--;
        $score += 300;
    }

    # ball gets new speed
    $ball->vx( sin( $ball->rad * 3.14 / 180 ) * 0.5 );
    $ball->vy( cos( $ball->rad * 3.14 / 180 ) * 0.5 );

    $ball->old_wheel( $ball->n_wheel );
    $ball->n_wheel(-1);

    return $particles_left;
}


# The final update that is drawn to the screen
sub draw_to_screen {
    my ( $fps, $level, $app, $ball, $particles, $particles_left ) =
      @_;

    #Blit the back ground surface to the window
    # Draw out all our failures to hit the particles
        SDL::Video::fill_rect( $app, $app_rect,
            SDL::Video::map_RGB( $app->format, 0, 0, 0 ) );
    
        # Blit the back ground surface to the window
        #TODO: optimize so we can show bg
     #    SDL::Video::blit_surface(
     #       $bg_surf, SDL::Rect->new( 0, 0, $bg_surf->w, $bg_surf->h ),
     #       $app,     SDL::Rect->new( 0, 0, $app->w,     $app->h )
     #   );
    
    


    #make a string with the FPS and level
    my $pfps = sprintf(
        "FPS:%.2f Level:%s Wheel [%2d, speed:%.2f] Left:%d Score: %d",
        $fps, $level->name, $ball->n_wheel, $particles->[ $ball->n_wheel ]->speed,
        $particles_left, $score
    );

    #write our string to the window
    SDL::GFX::Primitives::string_color( $app, 3, 3, $pfps, 0x00FF00FF );

    #Draw each particle
    $_->draw($app) foreach (@$particles);

    $ball->draw($app);

    #Update the entire window
    #This is one frame!
    SDL::Video::flip($app);
}


sub handle_chunk
{
    my ($mix_chunk) = shift;
     my $channel_number = SDL::Mixer::Channels::play_channel( -1, $mix_chunk, 0 );
      SDL::Mixer::Channels::volume( $channel_number, 10);

#    SDL::Mixer::Channels::halt_channel ($chan_lock) ;
}
