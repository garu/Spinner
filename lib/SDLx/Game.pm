package SDLx::Game;
use strict;
use warnings;
use SDLx::Game::Timer;


sub new {
    my $class = shift;
    my $self = bless {@_}, $class;
    $self->{delta} = SDLx::Game::Timer->new();
    $self->{delta}->start(); # should do this after on_load
    return $self;
}

sub run {
    my $self = shift;
    $self->{quit} = 0;

    while ( !$self->{quit} ) {
        $self->_event;

        $self->_move($self->{delta}->get_ticks());
	$self->{delta}->start();

        $self->_show();


    }

}

sub _event {
   my $self = shift;

    $self->{event} = SDL::Event->new() unless $self->{event};
    while ( SDL::Events::poll_event($self->{event}) ) {
        foreach my $event_handler ( @{ $self->{event_handlers} } ) {
		    $self->quit unless $event_handler->( $self->{event} );
        }
	}
}

sub _move {
   my $self = shift;
   my $delta_ticks = shift;
   foreach my $event_handler ( @ { $self->{move_handlers} } ) 
	{
		 $event_handler->($delta_ticks) ;
	}

}

sub _show {
  my $self = shift;
   my $delta_ticks = shift;
   foreach my $event_handler ( @ { $self->{show_handlers} } ) 
	{
	     $event_handler->($delta_ticks) ;
	}


}

sub quit {
    my $self = shift;

    $self->{quit} = 1;

}

sub add_move_handler {

    my $self = shift;

    push @{ $self->{move_handlers} }, shift;
}

sub add_event_handler {
    my $self = shift;

    push @{ $self->{event_handlers} }, shift;

}

sub add_show_handler {
    my $self = shift;

    push @{ $self->{show_handlers} }, shift;

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
