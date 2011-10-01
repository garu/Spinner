package Spinner::Level;
use strict;
use warnings;
use 5.10.0;
use Spinner;
use Spinner::Ball;
use Spinner::Wheel;
use Spinner::LevelData;

use SDL;
use SDL::Event;
use SDL::Events;
use SDL::Video;

sub load {
    my ( $class, $game ) = @_;
    my $self = bless {}, $class;

    # load out background
    $self->{background} = Spinner->load_image( 'data/bg.png', 1 );

    $self->{data}       = Spinner::LevelData->new;
    $self->{ball_image} = Spinner->load_image('data/ball.png');

    $self->{extra_life_at} = 10_000;

    #TODO: should we take 'dt' out of the picture as legacy?
    $self->{dt} = $game->dt * 100;

    $self->{move_id}  = $game->add_move_handler( sub  { $self->on_move(@_) } );
    $self->{event_id} = $game->add_event_handler( sub { $self->on_event(@_) } );
    $self->{show_id}  = $game->add_show_handler( sub  { $self->on_show(@_) } );

    Spinner->player( score => 0, lives => 3 );

    $self->load_level;

    return $self;
}

sub load_level {
    my $self  = shift;
    my $level = $self->{data};
    $level->load;
    $self->{particles_left} = scalar @{ $level->wheels };
    $self->{ball}           = Spinner::Ball->new(
        n_wheel => (
            $level->starting_wheel == -1
            ? int rand $self->{particles_left}
            : $level->starting_wheel
        ),
        rotating => ( Spinner->player('beginner') ? 0 : 1 ),
    );

    $self->{ball}->surface( $self->{ball_image} );
    $self->{init_time} = SDL::get_ticks();
}

sub next { return shift->{next} }

sub on_move {
    my $self  = shift;
    my $level = $self->{data};
    my $ball  = $self->{ball};
    return unless Spinner->player('lives');

    my $touched =
      $ball->update( $self->{dt}, $level->wheels, Spinner->player('beginner') );

    # losing condition
    if (    $ball->n_wheel >= 0
        and $level->wheels->[ $ball->n_wheel ]->visited )
    {
        Spinner->player->{lives} -= 1;
        if ( Spinner->player('lives') == 0 ) {
            $self->{next} = 'back';
            # force an event for game over
            my $event = SDL::Event->new;
            $event->type( SDL_USEREVENT );
            SDL::Events::push_event($event);
            return;
        }
        else {
            $self->load_level;
            return;
        }
    }

    # ball touched a wheel
    if ($touched) {
        # winning condition
        if ($touched == 1) {
            $self->show_win_message;
            $level->number( $level->number + 1 );
            Spinner->player->{score} += 1000;
            $self->load_level;
        }
        else {
            Spinner->player->{score} += 300;
        }
    }

    Spinner::Wheel::update( $self->{dt}, $level->wheels );

    if ( Spinner->player('score') >= $self->{extra_life_at} ) {
        Spinner->player->{lives} += 1;
        $self->{extra_life_at} = Spinner->player->{score} + 10_000;
    }

}

sub on_event {
    my ( $self, $event, $controller ) = @_;
    my $app   = Spinner->app;
    my $ball  = $self->{ball};
    my $level = $self->{data};

    # if 'next' was set on other places,
    # we catch it here:
    return $controller->stop() if $self->{next};

    # If we have a quit event (i.e player
    # clicks on [X]) we trigger the quit flag
    if ( $event->type == SDL_QUIT ) {
        $self->{next} = 'back';
        $controller->stop();
        return;
    }
    elsif ( $event->type == SDL_KEYDOWN ) {
        if ( Spinner->player('autoplay') ) {
            $self->{next} = 'back';
            $controller->stop();
            return;
        }

        given ( $event->key_sym ) {
            when (SDLK_SPACE) {
                $self->{particles_left} =
                  $self->check_ball_release( $ball, $level->wheels,
                    $self->{particles_left} );
            }
            when (SDLK_ESCAPE) {
                $self->{next} = 'back';
                $controller->stop();
                return;
            }
            when (SDLK_f) {
                SDL::Video::wm_toggle_fullscreen($app);
            }
            if ( Spinner->player('beginner') ) {
                when (SDLK_LEFT) {
                    $ball->rotating(1);
                }
                when (SDLK_RIGHT) {
                    $ball->rotating(-1);
                }
            }
        }
    }
    elsif ( Spinner->player('beginner') and $event->type == SDL_KEYUP ) {
        $ball->rotating(0);
    }

#    if ($AUTO && $frames > 0) {
#        my $cmd =  $AUTO->get_next_command($ball, $level->wheels);
#
#        $ball->rotating(-1) if $cmd eq 'R';
#
#        $ball->rotating(1) if $cmd eq 'L';
#
#        if ($cmd eq 'S') {
#            $ball->rotating(0);
#            $particles_left = check_ball_release($ball, $level->wheels, $particles_left, $dt)
#        }
#    }
    return 1;
}

sub on_show {
    my $self     = shift;
    my $app      = Spinner->app;
    my $app_rect = Spinner->get_camera;
    my $ball     = $self->{ball};
    my $level    = $self->{data};
    my $bg_surf  = $self->{background};

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
        "Level:%s Wheel [%2d, speed:%.2f] Left:%d Score: %d Lives: %d",
        $level->name,                              $ball->n_wheel,
        $level->wheels->[ $ball->n_wheel ]->speed, $self->{particles_left},
        Spinner->player('score'),                  Spinner->player('lives'),
    );

    #write our string to the window
    SDL::GFX::Primitives::string_color( $app, 3, 3, $pfps, 0x00FF00FF );

    #Draw each particle
    $_->draw foreach ( @{ $level->wheels } );

    $ball->draw;

    #Update the entire window
    #This is one frame!
    SDL::Video::flip($app);
}

sub show_win_message {
    my $self      = shift;
    my $app       = Spinner->app;
    my $init_time = $self->{init_time};

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
    my ( $self, $ball, $particles, $particles_left ) = @_;

    # warn $ball->ready;
    return $particles_left
      if !$ball->ready;    #the ball is not ready to release yet
        # we can't release the ball if it isn't attached to a wheel
    return $particles_left if $ball->n_wheel == -1;

    my $w = $particles->[ $ball->n_wheel ];

    if ( !$w->visited ) {

        # change wheel color so player knows it's touched
        $w->color(0x111111FF);
        $w->init_surface;

        $w->visited(1);
        $particles_left--;
    }

    # ball gets new speed
    $ball->vx( sin( $ball->rad * 3.14 / 180 ) * 0.8 );
    $ball->vy( cos( $ball->rad * 3.14 / 180 ) * 0.8 );

    $ball->old_wheel( $ball->n_wheel );
    $ball->n_wheel(-1);

    return $particles_left;
}

42;
