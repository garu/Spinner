package Spinner::AutoPlayer;

use strict;
use warnings;
use Carp;
use Math::Trig;

use Mouse;
has 'cmd'        => ( is => 'rw', isa => 'Str' );
has 'angle'     => ( is => 'rw', isa => 'Num' , default=> 0);
has 'diff'     => ( is => 'rw', isa => 'Int' , );
has 'rotating'     => ( is => 'rw', isa => 'Int' , );

my $DEBUG = 1;

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
    
    my $aim_at;
    foreach my $t ( @{$targets} ) {
        
         if ( !( $t->visited || $t == $targets->[$ball->n_wheel] ) ) {
          #warn 'Found one';
          $aim_at = $t;
	  last;
         }
    }
   # warn ' Aiming random' if !$aim_at;
    
    return int( rand(2 * pi) ) if !$aim_at;
    
    my $wheel_on = $targets->[ $ball->{n_wheel} ];
    
    my $x_diff = $wheel_on->x - $aim_at->x;
    my $y_diff =  $wheel_on->y - $aim_at->x;

    # calculate angle between vertical down and vector between wheels
         ### tan( theta ) = x_diff / y_diff 
         # theta = atan2 ( x_diff/ y_diff);
    my $angle = rad2deg ( atan2(-$y_diff, -$x_diff) + 270);
    $angle -= 360 while $angle > 360;


	
    return ($angle, $aim_at);
}

sub _handle_rotate
{
  my $self = $_[0];
  my $ball_angle = $_[1];
  my $ang = $self->angle();
  #start rotation if we have a angle_diff to handle
  if ( !$self->rotating && abs($ball_angle) != $ang ) 
  {
   #warn ' Not rotating ';
     if (  $ball_angle  >  $ang )
     {
      # warn ' Start Right';
       $self->rotating( 1 ) ;
       return 'R' ;
     }
     elsif (  $ball_angle  <  $ang  )
    {
     #warn ' Start Left';
      $self->rotating( -1 ) ;
     return 'L' ; #We rotate left
    } 
    else
    {
        my $pick = int( rand( 1 ) - rand( 1 ) );
        
        if( $pick > 0 ) 
        {$pick = 'R'; $self->rotating( 1 ) } 
        else { $pick = 'L' ; $self->rotating( -1 ) }
        
       
        
       
    }    
  }
  elsif ( $self->rotating != 0 )
  {
    
    if( $self->rotating == 1 &&  $ball_angle  >  $ang ) #we were rotating right
    {
      warn "Continue Right Trying to get to $ball_angle got to $ang" if $DEBUG;
       return 'R' #continue rotating
       
    }
    elsif ( $self->rotating == -1 && $ball_angle  <  $ang )
    {
     warn "Continue Left Trying to get to $ball_angle got to $ang"  if $DEBUG;
     return 'L' #continue rotating 
    }
    else
    {
      #shoot if we can't get any closer
      warn "Trying to get to $ball_angle got to $ang" if $DEBUG;
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
    my $targets = $_[2];
    my ($ang);
    if (!$self->angle)
    {
    ($ang) = _get_next_rad($ball, $targets);
    $self->angle ( $ang ) ;
    
   }
    
    
    #warn ' Going to angle '. $self->angle.' currently at '.$ball->rad ;
    
   return  $self->_handle_rotate($ball->rad);
    
   
}



#Add more AI stuff here later 
#we can do race against computer
#
1; #no not 42 :p
