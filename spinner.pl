#!/usr/bin/perl

use 5.10.0;
use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/lib";

use SDLx::Game;
use Spinner;
use Spinner::MainMenu;
use Spinner::HighScore;
use Spinner::Level;


use Data::Dumper;
use Carp;
my $DEBUG = 0;

Spinner::Sounds->init;
Spinner::Sounds->start_music('data/bg.ogg');

my $gameflow = {
    'Spinner::MainMenu' => {
        new_game    => 'Spinner::Level',
        high_scores => 'Spinner::HighScore',
    },
    'Spinner::HighScore' => {
        back => 'Spinner::MainMenu',
    },
    'Spinner::Level' => {
        back       => 'Spinner::MainMenu',
        high_score => 'Spinner::HighScore',
    },
};

Spinner->init;
my $game = SDLx::Game->new;
my $current_class = 'Spinner::MainMenu';

while (1) {
    my $state = $current_class->load($game);
    $game->run;
    $game->remove_all_handlers;

    my $transition = $state->next || last;
    # $current_class = $gameflow->{transitions}->{$result};

    if (exists $gameflow->{$current_class}->{$transition}) {
        $current_class = $gameflow->{$current_class}->{$transition};
    }
    else {
        die "invalid transition '$transition' for class $current_class!";
    }
}
exit;


#TODO: refactor those
#sub enter_highscore {
#    # check if player made a high score
#    my $high_score = Spinner::load_data_file('data/highscore.dat');
#    if (not defined $high_score) {
#        push @{$high_score}, { name => 'SpinnerMaster', score => 0 }
#            foreach 0..9
#    }
#    my $rank = 0;
#    while (exists $high_score->[$rank]) {
#        last if $score > $high_score->[$rank]->{score};
#        $rank++;
#    }
#    if ($rank >= 10 ) {
#	    warn 'Haha! Don\'t meet top 10! ';
#    	return;
#    }
#
#    # remove last entry
#    pop @{$high_score};
#
#    my $font = SDL::TTF::open_font('data/metro.ttf', 18)
#        or Carp::croak 'Error opening font: ' . SDL::get_error;
#    my $color = SDL::Color->new(100,255,100);
#
#    my $show = 1;
#    my $name = '';
#    my $event = SDL::Event->new;
#    while ($show) {
#        while ( SDL::Events::poll_event($event) ) {
#            if ($event->type == SDL_KEYDOWN) {
#                my $key = $event->key_sym;
#                if (length $name == 13
#                   or $key == SDLK_RETURN or $key == SDLK_KP_ENTER
#                ) {
#                    $show = 0;
#                }
#                elsif ( ($key >= SDLK_0 and $key <= SDLK_9)
#                     or ($key >= SDLK_a and $key <= SDLK_z)
#                ) {
#                    $name .= chr($key);
#                }
#            }
#        }
#        SDL::Video::fill_rect( $app, SDL::Rect->new(100,100, 520,170),
#                SDL::Video::map_RGB( $app->format, 0, 0, 0 )
#        );
#        SDL::Video::fill_rect( $app, SDL::Rect->new(110,110, 500,150),
#                SDL::Video::map_RGB( $app->format, 0, 50, 0 )
#        );
#
#        # blit the window title
#        my $title = SDL::TTF::render_text_blended(
#                $font, "New High Score! $score", $color
#                ) or Carp::croak 'TTF render error: ' . SDL::get_error;
#        SDL::Video::blit_surface(
#                $title,
#                SDL::Rect->new(0,0,$title->w, $title->h),
#                $app,
#                SDL::Rect->new(200, 130, $app->w, $app->h),
#        );
#
#        # blit the user name
#        my $player = SDL::TTF::render_text_blended($font, $name . '_', $color)
#            or Carp::croak 'TTF render error: ' . SDL::get_error;
#        SDL::Video::blit_surface(
#                $player, SDL::Rect->new(0,0,$player->w, $player->h),
#                $app, SDL::Rect->new($app->w / 2 - 10 * length($name) - 50, 190, $app->w, $app->h),
#        );
#
#        SDL::Video::flip($app);
#
#    }
#
#    # add the new score to the table
#    splice @{$high_score}, $rank, 0, { name => $name, score => $score };
#    Spinner::write_data_file('data/highscore.dat', $high_score);
#
#    return high_scores();
#}
#
## auto_game plays a random level
## while the user is idle
#sub auto_game {
#    $quit = 0;
#    $AUTO = Spinner::AutoPlayer->new;
#    my $level = Spinner::Level->new;
#
#    while ( !$quit ) {
#        $score = 0;
#        $level->randomize->load;
#        play($level);
#    }
#    $AUTO = undef;
#}
#
