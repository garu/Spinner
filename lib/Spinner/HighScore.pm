package Spinner::HighScore;
use strict;
use warnings;

use SDL;
use SDL::Rect;
use SDL::Video;
use SDL::TTF;
use SDL::Event;
use SDL::Events;
use Spinner;

sub load {
    my ($class, $game) = @_;
    SDL::TTF::init;

    my $self = bless {}, $class;

    # load out background
    $self->{background} = Spinner->load_image('data/bg.png', 1);

    # load the highscore chart
    my $high_score = Spinner::load_data_file('data/highscore.dat');
    if (not defined $high_score) {
        push @{$high_score}, { name => 'SpinnerMaster', score => 0 }
            foreach 0..9
    }
    $self->{high_score} = $high_score;

    # load the font
    $self->{font} = SDL::TTF::open_font('data/metro.ttf', 18)
        or Carp::croak 'Error opening font: ' . SDL::get_error;
    $self->{font_color} = SDL::Color->new(100,255,100);
    $self->{title_color} = SDL::Color->new(235,30,30);

    # set our hooks
    $self->{event_id} = $game->add_event_handler( sub {$self->on_event(@_)} );
    $self->{show_id}  = $game->add_show_handler( sub {$self->on_show(@_)} );

    return $self;
}

sub next { return shift->{next} }

sub on_event {
    my ($self, $event) = @_;

    if ($event->type == SDL_QUIT or $event->type == SDL_KEYDOWN) {
        $self->{next} = 'back';
        return;
    }
    return 1;
}

sub on_show {
    my $self = shift;
    my $app = Spinner->app;
    my $app_rect = Spinner->get_camera;

    SDL::Video::fill_rect( $app, $app_rect,
        SDL::Video::map_RGB( $app->format, 0, 0, 0 ) );

    # Blit the back ground surface to the window
    my $bg_surf = $self->{background};
    SDL::Video::blit_surface(
        $bg_surf, SDL::Rect->new( 0, 0, $bg_surf->w, $bg_surf->h ),
        $app,     SDL::Rect->new( 0, 0, $app->w,     $app->h )
    );

    # blit the window title
    my $title = SDL::TTF::render_text_blended(
            $self->{font}, 'HIGH SCORES', $self->{title_color}
            ) or Carp::croak 'TTF render error: ' . SDL::get_error;
    SDL::Video::blit_surface(
            $title,
            SDL::Rect->new(0, 0, $title->w, $title->h),
            $app,
            SDL::Rect->new($app->w / 2 - 100, 20, $app->w, $app->h),
    );


    my $h = 30;
    foreach my $score ( @{$self->{high_score}} ) {
        # make our string...
        my $string = $score->{name} . '         ' . $score->{score};

        # and render it
        my $surface = SDL::TTF::render_text_blended(
                $self->{font}, $string, $self->{font_color}
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

42;
