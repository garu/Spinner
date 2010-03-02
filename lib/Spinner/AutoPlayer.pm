package Spinner::AutoPlayer;

use strict;
use warnings;
use Carp;

use Mouse;
has 'cmd'        => ( is => 'rw', isa => 'Str' );
has 'counter'     => ( is => 'rw', isa => 'Int' , default=> 0);


# Choose a next command
# Returns an array 
#
sub get_next_command
{ 
   my $self = shift;

   if ($self->counter > 0)
   {
	$self->counter ( $self->counter - 1);

	return $self->cmd();
   }

   my @options = qw/ R L S/; # Right Left or Shoot

   my $option = $options[ int ( rand( $#options + 1 )  ) ]; #get one of those options

   my $counter = 1;
    $counter = int( rand(15) + 10 ) if ($option =~ /R|L/); #for how long


    $self->cmd( $option); $self->counter( $counter );
   

    return   $option;

}


#Add more AI stuff here later 
#we can do race against computer
#
1; #no not 42 :p
