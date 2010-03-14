#!/usr/bin/perl

use 5.10.0;
use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/lib";
use Spinner;
use Spinner::Sounds;
use Spinner::Ball;
use Spinner::Wheel;
use Spinner::Level;
use Spinner::AutoPlayer;
use SDLx::Widget::Menu;

use SDL;
use SDL::Video;
use SDL::Surface;
use SDL::Rect;
use SDL::Events;
use SDL::Event;
use SDL::Color;
use SDL::GFX::Primitives;
use SDL::Image;
use SDL::TTF;
SDL::TTF::init();

use Data::Dumper;
use Carp;
my $DEBUG = 0;

my $AUTO = $ARGV[0];

my $app = Spinner->init;

Spinner::Sounds->init;
Spinner::Sounds->start_music('data/bg.ogg');

#Some global variables used thorugh out the game
my $app_rect = SDL::Rect->new( 0, 0, 800, 600 );
my $fps = 30;

# The surface of the background
my $bg_surf = init_bg_surf($app);

my $ball_image = Spinner->load_image('data/ball.png');
my $spinner_menu = Spinner->load_image('data/main.png');

SDL::Video::wm_set_caption( 'Spinner', 'spinner' );

my $quit  = 0;

# Spinner::Player, anyone?
my $score    = 0;
my $lives    = 3;
my $beginner = 0;

if ($AUTO) {
    auto_game();
}
else {
    menu();
}

sub menu {
    my $event = SDL::Event->new();
    my $menu_quit = 0;

    my $menu = SDLx::Widget::Menu->new(
            font         => 'data/metro.ttf',
            font_color   => [2, 200, 5],
            select_color => [5, 2, 200],
            change_sound => 'data/menu_select.ogg',
       )->items(
            'New Game'    => \&game,
            'Load Game'   => sub {},
            'How to Play' => sub {},
            'High Scores' => \&high_scores,
            'Options'     => sub {},
            'Quit'        => sub { $menu_quit = 1 },
    );

    my $time = SDL::get_ticks();
    while ( !$menu_quit ) {
        if (SDL::get_ticks() - $time > 10000) {
            $AUTO = Spinner::AutoPlayer->new;
            auto_game();
            $AUTO = undef;
            $time = SDL::get_ticks();
        }

        #Get all events from the event queue in our event
        while ( SDL::Events::poll_event($event) ) {

            # If we have a quit event (i.e player 
            # clicks on [X]) we trigger the quit flag
            if ( $event->type == SDL_QUIT ) {
                $menu_quit = 1;
            }
            elsif ( $event->type == SDL_KEYDOWN ) {
                # reset our "demo" clock
                $time = SDL::get_ticks();

                $menu_quit = 1 if $event->key_sym == SDLK_ESCAPE;
                SDL::Video::wm_toggle_fullscreen($app)
                    if $event->key_sym == SDLK_f;
            }
            elsif (   $event->key_sym == SDLK_RETURN
                   or $event->key_sym == SDLK_KP_ENTER
                  ) {

                # reset our "demo" clock
                $time = SDL::get_ticks();
            }

            # let our menu object have a go as well
            $time = SDL::get_ticks() if $menu->event_hook($event);
        }

        SDL::Video::fill_rect(
            $app,
            $app_rect,
            SDL::Video::map_RGB( $app->format, 0, 0, 0 )
        );
    
        SDL::Video::blit_surface(
            $spinner_menu,
            SDL::Rect->new( 0, 0, $spinner_menu->w, $spinner_menu->h ),
            $app,
            SDL::Rect->new( 150, 0, $app->w, $app->h ),
        );

        $menu->render($app);
        SDL::Video::flip($app);
    }
}

sub enter_highscore {
    # check if player made a high score
    my $high_score = Spinner::load_data_file('data/highscore.dat');
    my $rank = 0;
    while (exists $high_score->[$rank]) {
        last if $score > $high_score->[$rank]->{score};
        $rank++;
    }
    if ($rank >= 10 )
    {
	warn 'Haha! Don\'t meet top 10! ';
	return	
    }

    # remove last entry
    pop @{$high_score};

    my $font = SDL::TTF::open_font('data/metro.ttf', 18)
        or Carp::croak 'Error opening font: ' . SDL::get_error;
    my $color = SDL::Color->new(100,255,100);

    my $show = 1;
    my $name = '';
    my $event = SDL::Event->new;
    while ($show) {
        while ( SDL::Events::poll_event($event) ) {
            if ($event->type == SDL_KEYDOWN) {
                my $key = $event->key_sym;
                if (length $name == 13
                   or $key == SDLK_RETURN or $key == SDLK_KP_ENTER
                ) {
                    $show = 0;
                }
                elsif ( ($key >= SDLK_0 and $key <= SDLK_9)
                     or ($key >= SDLK_a and $key <= SDLK_z)
                ) {
                    $name .= chr($key);
                }
            }
        }
        SDL::Video::fill_rect( $app, SDL::Rect->new(100,100, 520,170),
                SDL::Video::map_RGB( $app->format, 0, 0, 0 )
        );
        SDL::Video::fill_rect( $app, SDL::Rect->new(110,110, 500,150),
                SDL::Video::map_RGB( $app->format, 0, 50, 0 )
        );

        # blit the window title
        my $title = SDL::TTF::render_text_blended(
                $font, "New High Score! $score", $color
                ) or Carp::croak 'TTF render error: ' . SDL::get_error;
        SDL::Video::blit_surface(
                $title,
                SDL::Rect->new(0,0,$title->w, $title->h),
                $app,
                SDL::Rect->new(200, 130, $app->w, $app->h),
        );

        # blit the user name
        my $player = SDL::TTF::render_text_blended($font, $name . '_', $color)
            or Carp::croak 'TTF render error: ' . SDL::get_error;
        SDL::Video::blit_surface(
                $player, SDL::Rect->new(0,0,$player->w, $player->h),
                $app, SDL::Rect->new($app->w / 2 - 10 * length($name) - 50, 190, $app->w, $app->h),
        );

        SDL::Video::flip($app);

    }

    # add the new score to the table
    splice @{$high_score}, $rank, 0, { name => $name, score => $score };
    Spinner::write_data_file('data/highscore.dat', $high_score);

    return high_scores();
}


sub high_scores {
    my $show = 1;

    my $high_score = Spinner::load_data_file('data/highscore.dat');
    my $font = SDL::TTF::open_font('data/metro.ttf', 18)
        or Carp::croak 'Error opening font: ' . SDL::get_error;
    my $font_color = SDL::Color->new(100,255,100);
    my $title_color = SDL::Color->new(235,30,30);

    # Get an event object to snapshot the SDL event queue
    my $event = SDL::Event->new();
    while ($show) {
        while ( SDL::Events::poll_event($event) ) {
            $show = 0 if    $event->type == SDL_QUIT
                         || $event->type == SDL_KEYDOWN
                      ;
        }
        SDL::Video::fill_rect( $app, $app_rect,
            SDL::Video::map_RGB( $app->format, 0, 0, 0 ) );

        # Blit the back ground surface to the window
        SDL::Video::blit_surface(
            $bg_surf, SDL::Rect->new( 0, 0, $bg_surf->w, $bg_surf->h ),
            $app,     SDL::Rect->new( 0, 0, $app->w,     $app->h )
        );

        # blit the window title
        my $title = SDL::TTF::render_text_blended(
                $font, 'HIGH SCORES', $title_color
                ) or Carp::croak 'TTF render error: ' . SDL::get_error;
        SDL::Video::blit_surface(
                $title,
                SDL::Rect->new(0,0,$title->w, $title->h),
                $app,
                SDL::Rect->new($app->w / 2 - 100, 20, $app->w, $app->h),
        );


        my $h = 30;
        foreach my $score ( @{$high_score} ) {
            my $string = $score->{name} . '         ' . $score->{score};
            my $surface = SDL::TTF::render_text_blended(
                    $font, $string, $font_color
                    ) or Carp::croak 'TTF render error: ' . SDL::get_error;
            SDL::Video::blit_surface(
                    $surface,
                    SDL::Rect->new(0,0,$surface->w, $surface->h),
                    $app,
                    SDL::Rect->new($app->w / 2 - 230, $h += 50,
                                   $app->w, $app->h ),
            );
        }

        SDL::Video::flip($app);
    }

    # return positive to reset demo timer
    return 1;
}

sub game {
    $quit = 0;
    my $level = Spinner::Level->new;

    $score = 0;
    $lives = 3;
    while ( $level->load ) {
        if ( play($level) ) {
            $level->number( $level->number + 1 );
            $score += 1000;
        }
        else {
            $lives--;
            if ($lives == 0) {
                SDL::GFX::Primitives::string_color(
                    $app,
                    $app->w / 2 - 150,
                    $app->h / 2 - 4,
                    "YOU LOSE!!! Score: $score", 0x00FF00FF
                );
                SDL::Video::flip($app);
                SDL::delay(1000);
                enter_highscore();
		SDL::delay(1000);

                last;
            }
        }
        last if $quit;
    }
    # return positive to reset demo timer
    return 1;
}

# auto_game plays a random level
# while the user is idle
sub auto_game {
    $quit = 0;
    $AUTO = Spinner::AutoPlayer->new;
    my $level = Spinner::Level->new;

    while ( !$quit ) {
        $score = 0;
        $level->randomize->load;
        play($level);
    }
    $AUTO = undef;
}

# create the given level. returns true if level is over,
# or false if player died.
sub play {
    my $level = shift;

    my $particles_left = scalar @{$level->wheels};

    # start the ball in a random wheel
    my $ball = Spinner::Ball->new(
                  n_wheel  => ($level->starting_wheel == -1
                               ? int rand $particles_left
                               : $level->starting_wheel
                              ),
                  rotating => ($beginner ? 0 : 1),
               );
    $ball->surface( $ball_image );

    # Get an event object to snapshot the SDL event queue
    my $event = SDL::Event->new();

    # SDL time is recorded in ticks,
    # Ticks are the milliseconds since the SDL library was loaded into memory
    my $time = SDL::get_ticks();

    # This is our level continue flag
    my $continue = 1;

    # Init some level globals for time calculations
    my ( $dt, $t, $accumulator, $cur_time ) = ( 0.001, 0, 0, SDL::get_ticks() );

    #Keep a copy of the cur_time for Frames per Rate calculations
    my $init_time = $cur_time;

    #Keep a count of number of frames
    my $frames = 0;

    # gotta give the player *something* :)
    my $extra_live_at = $score + 10_000;

    #Our level game loop
    while ( $continue && !$quit ) {

        #Get all events from the event queue in our event
        while ( SDL::Events::poll_event($event) ) {
            #If we have a quit event i.e click on [X] trigger the quit flage
            if ( $event->type == SDL_QUIT ) {
                $quit = 1;
            }
            elsif ( $event->type == SDL_KEYDOWN ) {
                if ($AUTO) {
                    $quit = 1;
                    last;
                }
                given ( $event->key_sym ) {
                    when (SDLK_SPACE) {
                        $particles_left =
                            check_ball_release( $ball,  $level->wheels,
                                                $particles_left
                                              );
                    }
                    when (SDLK_ESCAPE) {
                        $quit = 1;
                    }
                    when (SDLK_f) {
                        SDL::Video::wm_toggle_fullscreen($app);
                    }
                    if ($beginner) {
                        when (SDLK_LEFT) {
                            $ball->rotating(1);
                        }
                        when (SDLK_RIGHT) {
                            $ball->rotating(-1);
                        }
                    }
                }
            }
            elsif ( $beginner and $event->type == SDL_KEYUP ) {
                $ball->rotating(0);
            }
            warn 'event' if $DEBUG;
        }

        if ($AUTO && $frames > 0) {
            my $cmd =  $AUTO->get_next_command($ball, $level->wheels);

            $ball->rotating(-1) if $cmd eq 'R';

            $ball->rotating(1) if $cmd eq 'L';

            if ($cmd eq 'S') {
                $ball->rotating(0);
                $particles_left = check_ball_release($ball, $level->wheels, $particles_left, $dt) 
            }
#$AUTO = undef if $quit == 1;
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
        my $on_last_wheel;
        # release the time in $dt amount of time so we have smooth animations
        while ( $accumulator >= $dt && $continue ) {

            # update our particle locations base on dt time
            # (x,y) = dv*dt
            ######iterate_step($dt);
            my $won = $ball->update( $dt, $level->wheels, $beginner );
            Spinner::Wheel::update( $dt, $level->wheels);

            # winning condition (FIXME: make this better)
            $on_last_wheel = 1 if $won;

            # losing condition
            if ( $ball->n_wheel >= 0 
                and $level->wheels->[ $ball->n_wheel ]->visited 
            ) {
                $continue = 0;
            }

            #dequeue our time accumulator
            $accumulator -= $dt;

            #update how much real time we have animated
            $t += $dt;
            warn 'acc' if $DEBUG;
        }
        if ( $score >= $extra_live_at ) {
            $lives++;
            $extra_live_at = $score + 10_000;
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
        if ($on_last_wheel) {
            show_win_message($app, $init_time);
            last;
        }
    }
    return $continue;
}

# Create a background surface once so we
# Can keep using it as many times as we need
sub init_bg_surf {
    my $app = shift;
    my $bg = Spinner->load_image('data/bg.png', 1);
    return $bg;
}

sub show_win_message {
    my ($app, $init_time) = @_;

    my $secs_to_win = ( SDL::get_ticks() - $init_time / 1000 );
    my $str = sprintf( "Level completed in : %2d millisecs !!!", $secs_to_win );
    SDL::GFX::Primitives::string_color(
            $app,
            $app->w / 2 - 150,
            $app->h / 2 - 4,
            $str, 0x00FF00FF
    );

    SDL::Video::flip($app);
    SDL::delay(1000);
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
        $w->init_surface;

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
         SDL::Video::blit_surface(
            $bg_surf, SDL::Rect->new( 0, 0, $bg_surf->w, $bg_surf->h ),
            $app,     SDL::Rect->new( 0, 0, $app->w,     $app->h )
        );
    
    


    #make a string with the FPS and level
    my $pfps = sprintf(
        "FPS:%.2f Level:%s Wheel [%2d, speed:%.2f] Left:%d Score: %d Lives: %d",
        $fps, $level->name, $ball->n_wheel, $particles->[ $ball->n_wheel ]->speed,
        $particles_left, $score, $lives
    );

    #write our string to the window
    SDL::GFX::Primitives::string_color( $app, 3, 3, $pfps, 0x00FF00FF );

    #Draw each particle
    $_->draw foreach (@$particles);

    $ball->draw;

    #Update the entire window
    #This is one frame!
    SDL::Video::flip($app);
}


