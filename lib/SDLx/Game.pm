package SDLx::Game;
use strict;
use warnings;
use SDLx::Game::Timer;
use Data::Dumper;

sub new {
    my $class = shift;
    my $self = bless {@_}, $class;
    $self->{delta} = SDLx::Game::Timer->new();
    $self->{delta}->start();    # should do this after on_load
    $self->{dt} = 0.01;

    return $self;
}

sub run {
    my $self = shift;
    $self->{quit} = 0;
    my $accumulator = 0;
    while ( !$self->{quit} ) {
        $self->_event;
        my $delta_time = $self->{delta}->get_ticks();
        $accumulator += $delta_time;

        while ( $accumulator >= $self->{dt} && !$self->{quit} ) {
            $self->_move( $self->{dt} );
            $accumulator -= $self->{dt};

            #update how much real time we have animated

        }
        $self->{delta}->start();

        $self->_show($delta_time);

    }

}

sub _event {
    my $self = shift;

    $self->{event} = SDL::Event->new() unless $self->{event};
    while ( SDL::Events::poll_event( $self->{event} ) ) {
	SDL::Events::pump_events();
        foreach my $event_handler ( @{ $self->{event_handlers} } ) {
            $self->quit unless $event_handler->( $self->{event} );
        }
    }
}

sub _move {
    my $self        = shift;
    my $delta_ticks = shift;
    foreach my $move_handler ( @{ $self->{move_handlers} } ) {

        $move_handler->($delta_ticks);

    }

}

sub _show {
    my $self        = shift;
    my $delta_ticks = shift;
    foreach my $event_handler ( @{ $self->{show_handlers} } ) {
        $event_handler->($delta_ticks);
    }

}

sub quit {
    my $self = shift;

    $self->{quit} = 1;

}

sub _add_handler {
    my ( $arr_ref, $handler ) = @_;
    push @{$arr_ref}, $handler;
    return $#{$arr_ref}

}

sub add_move_handler {
    $_[0]->{move_handlers} = [] if !$_[0]->{move_handlers};
    return _add_handler( $_[0]->{move_handlers}, $_[1] );

}

sub add_event_handler {
    $_[0]->{event_handlers} = [] if !$_[0]->{event_handlers};
    return _add_handler( $_[0]->{event_handlers}, $_[1] );
}

sub add_show_handler {
    $_[0]->{show_handlers} = [] if !$_[0]->{show_handlers};
    return _add_handler( $_[0]->{show_handlers}, $_[1] );
}

sub _remove_handler {
    my ( $arr_ref, $id ) = @_;

    return splice( @{$arr_ref}, $id, 1 );

}

sub remove_move_handler {
    return _remove_handler( $_[0]->{move_handlers}, $_[1] );
}

sub remove_event_handler {
    return _remove_handler( $_[0]->{event_handlers}, $_[1] );
}

sub remove_show_handler {
    return _remove_handler( $_[0]->{show_handlers}, $_[1] );
}

1;    #not 42 man!

=pod 

=head1 NAME

SDLx::Game - Handles the game loop 

=head2 Description

Using http://www.lazyfoo.net/SDL_tutorials/lesson32/index.php as our base

=head1 METHODS


=head2 run

=head2 add_move_handler

Register a  callback to update objects

=head2 add_show_handler

Register a  callback to render objects


=head2 add_event_handler

Register a callback to handle events SDL or game like


=head2 current_fps

=cut
