package Spinner::MainMenu;
use strict;
use warnings;

use Spinner;
use SDL;
use SDL::Event;
use SDL::Events;
use SDL::Video;
use SDLx::Widget::Menu;

sub load {
    my ($class, $game) = @_;

    my $self = bless {}, $class;

    $self->{logo} = Spinner->load_image('data/main.png');

    $self->{menu} = SDLx::Widget::Menu->new(
            font         => 'data/metro.ttf',
            font_color   => [2, 200, 5],
            select_color => [5, 2, 200],
            change_sound => 'data/menu_select.ogg',
    )->items(
            'New Game'    => sub { $self->{next} = 'new_game'   ; $game->stop },
            'Load Game'   => sub { $self->{next} = 'load_game'  ; $game->stop },
            'How to Play' => sub { $self->{next} = 'howto'      ; $game->stop },
            'High Scores' => sub { $self->{next} = 'high_scores'; $game->stop },
            'Options'     => sub { $self->{next} = 'options'    ; $game->stop },
            'Quit'        => sub {                                $game->stop },
    );

    $self->{'time'}   = SDL::get_ticks();
    $self->{move_id}  = $game->add_move_handler( sub {$self->on_move(@_)} );
    $self->{event_id} = $game->add_event_handler( sub {$self->on_event(@_)} );
    $self->{show_id}  = $game->add_show_handler( sub {$self->on_show(@_)} );

    return $self;
}

sub next { return shift->{next} }

sub on_move {
    my $self = shift;

    if (SDL::get_ticks() - $self->{'time'} > 10000) {
#        $AUTO = Spinner::AutoPlayer->new;
#        auto_game();
        print STDERR "we should have started an autoplay game now\n";
#        $AUTO = undef;
        $self->{'time'} = SDL::get_ticks();
    }
}

sub on_event {
    my ($self, $event, $controller) = @_;

    # If we have a quit event (i.e player 
    # clicks on [X]) we trigger the quit flag
    if ( $event->type == SDL_QUIT ) {
        $controller->stop();
        return
    }
    elsif ( $event->type == SDL_KEYDOWN ) {
        # reset our "demo" clock
        $self->{'time'} = SDL::get_ticks();

        return if $event->key_sym == SDLK_ESCAPE;
        SDL::Video::wm_toggle_fullscreen( Spinner->app )
            if $event->key_sym == SDLK_f;
    }
    elsif (   $event->key_sym == SDLK_RETURN
           or $event->key_sym == SDLK_KP_ENTER
          ) {

        # reset our "demo" clock
        $self->{'time'} = SDL::get_ticks();
    }

    # let our menu object have a go as well
    return $self->{menu}->event_hook($event);
}

sub on_show {
    my $self = shift;
    my $app = Spinner->app;
    my $app_rect = Spinner->get_camera;

    SDL::Video::fill_rect(
        $app,
        $app_rect,
        SDL::Video::map_RGB( $app->format, 0, 0, 0 )
    );

    SDL::Video::blit_surface(
        $self->{logo},
        SDL::Rect->new( 0, 0, $self->{logo}->w, $self->{logo}->h ),
        $app,
        SDL::Rect->new( 150, 0, $app->w, $app->h ),
    );

    $self->{menu}->render($app);
    SDL::Video::flip($app);
}


42;
