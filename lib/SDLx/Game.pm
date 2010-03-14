package SDLx::Game;
use strict;
use warnings;

sub new {
    my $class = shift;
    my $self = bless {@_}, $class;

    return $self;

}

sub run {
    my $self = shift;
    $self->{quit} = 0;
    my $delta_ticks = 0;

    while ( !$self->{quit} ) {
        $self->_event;

        $self->_move($delta_ticks);

        $self->_show();

    }

}

sub _event {

}

sub _move {

}

sub _show {

}

sub quit {
    my $self = shift;

    $self->{quit} = 1;

}

sub on_move {

    my $self = shift;

    push @{ $self->{on_move} }, shift;
}

sub on_event {
    my $self = shift;

    push @{ $self->{on_event} }, shift;

}

sub on_show {
    my $self = shift;

    push @{ $self->{on_show} }, shift;

}

1;    #not 42 man!

=pod 

=head1 NAME

SDLx::Game - Handles the game loop 

=head2 Description

Using http://www.lazyfoo.net/SDL_tutorials/lesson32/index.php as our base

=head1 METHODS


=head2 run

=head2 on_move

Register a  callback to update objects

=head2 on_show

Register a  callback to render objects


=head2 on_event

Register a callback to handle events SDL or game like


=head2 current_fps

=cut
