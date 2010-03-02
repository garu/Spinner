package Spinner::AutoPlayer;

use strict;
use warnings;
use Carp;

use Mouse;
has 'cmd'        => ( is => 'rw', isa => 'Str' );
has 'angle'     => ( is => 'rw', isa => 'Num' , default=> 0);
has 'diff'     => ( is => 'rw', isa => 'Int' , );
has 'rotating'     => ( is => 'rw', isa => 'Int' , );


# Choose a next command
# Returns an array 
#
#sub get_next_command
#{ 
#   my $self = shift;
#
#   if ($self->counter > 0)
#   {
#	$self->counter ( $self->counter - 1);
#
#	return $self->cmd();
#   }
#
#   my @options = qw/ R L S/; # Right Left or Shoot
#
#   my $option = $options[ int ( rand( $#options + 1 )  ) ]; #get one of those options
#
#   my $counter = 1;
#    $counter = int( rand(15) + 10 ) if ($option =~ /R|L/); #for how long
#
#
#    $self->cmd( $option); $self->counter( $counter );
#   
#
#    return   $option;
#
#}

sub _attached
{
    my $ball = shift;
    
    return $ball->n_wheel >= 0;
}


sub _get_next_rad
{
    return if !_attached($_[0]);
    my $ball = shift;
    my $targets = shift;
    
    my @target_now = @{$targets};
    # Pick the first none dead target
    
    my $aim_at;
    foreach my $t ( @target_now)
    {
        
         if ( !( $t->visited || $t == $target_now[$ball->n_wheel] ) )         
         {
          #warn 'Found one';
          $aim_at = $t
         }
        
        
        
    }
   # warn ' Aiming random' if !$aim_at;
    
    return int( rand(2 * 3.14) ) if !$aim_at;
    
    my $wheel_on = $target_now[$ball->{n_wheel}];
    
    my $x_diff = $ball->{x} - $aim_at->{x};
    my $y_diff = $aim_at->{y} - $ball->{y};

    # calculate angle between vertical down and vector between wheels
         ### tan( theta ) = x_diff / y_diff 
         # theta = atan2 ( x_diff/ y_diff);
    my $angle = atan2($y_diff, $x_diff); 
    #$angle += 360 if $angle < 0;
    return ($angle, $aim_at);
       
}

sub _handle_rotate
{
  my $self = $_[0];
  my $angle_diff = $_[1];
  
  #start rotation if we have a angle_diff to handle
  if ( !$self->rotating && abs($angle_diff) > 0 ) 
  {
   #warn ' Not rotating ';
     if ( int( $angle_diff ) >  0)
     {
      # warn ' Start Right';
       $self->rotating( 1 ) ;
       return 'R' ;
     }
     elsif (  int( $angle_diff ) < 1 )
    {
     #warn ' Start Left';
      $self->rotating( -1 ) ;
     return 'L' ; #We rotate left
    }     
  }
  elsif ( $self->rotating != 0 )
  {
    
    if( $self->rotating == 1 &&  $angle_diff >= 0) #we were rotating right
    {
      #warn ' Continue Right '.$angle_diff;
       return 'R' #continue rotating
       
    }
    elsif ( $self->rotating == -1 && $angle_diff <= 0)
    {
     #warn ' Continue Left '.$angle_diff  ;
     return 'L' #continue rotating 
    }
    else
    {
      #shoot if we can't get any closer
      $self->angle( 0 );
      $self->rotating( 0 );
      return 'S'  #We shoot
    }
   
  }
  
   
   
      
     
 
}

sub get_next_command
{
    return 'W' if !_attached($_[1]); # wait to attach onto a ball
    my $self = $_[0];
    
    my $ball = $_[1];
    my ($ang);
    if (!$self->angle)
    {
    ($ang) = _get_next_rad($_[1], $_[2]);
    $self->angle ( $ang ) ;
    
   }
    
    my $angle_diff = $ball->rad - $self->angle; 
    #warn ' Going to angle '. $self->angle.' currently at '.$ball->rad ;
    
   return  $self->_handle_rotate($angle_diff);
    
   
}



#Add more AI stuff here later 
#we can do race against computer
#
1; #no not 42 :p
