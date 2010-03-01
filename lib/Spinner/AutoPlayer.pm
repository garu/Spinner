package Spinner::AutoPlayer;

use strict;
use warnings;
use Carp;

use Mouse;
has 'cmd'        => ( is => 'rw', isa => 'Str' );
has 'counter'     => ( is => 'ro', isa => 'Int' );


# Choose a next command
# Returns an array 
#
sub get_next_command
{ 
   my $self = shift;
   my @options = qw/ R L S/; # Right Left or Shoot

   my $option = $options[ rand( $#options ) ]; #get one of those options

   my $counter;
    $counter = rand(1000) if ($option =~ /R|L/); #for how long


    $self->cmd( $option); $self->counter( $counter );
   

    return  ( $option, $counter);

}


#Add more AI stuff here later 
#we can do race against computer
#
1; #no not 42 :p
