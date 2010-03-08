package Spinner::AutoPlayer;

use strict;
use warnings;
use Carp;
use Math::Trig;
use SDL;

use Mouse;
has 'cmd'      => ( is => 'rw', isa => 'Str' );
has 'angle'    => ( is => 'rw', isa => 'Num' , default=> 0);
has 'diff'     => ( is => 'rw', isa => 'Int' );
has 'rotating' => ( is => 'rw', isa => 'Int' );
has 'timeout'  => ( is => 'rw', isa => 'Int',
                    default => sub { SDL::get_ticks() }
                  );

my $DEBUG = 0;
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
	my $dist = -1;
    foreach my $t ( @{$targets} ) {
        
         if ( !( $t->visited || $t == $targets->[$ball->n_wheel] ) ) {
          #warn 'Found one';
	  my $l_dist = ( $t->x - $ball->x ) **2 + ( $t->y - $ball->x ) **2;
	  if ( $dist == -1 || ($dist != -1 && $l_dist <= $dist ) )
	  {
		$dist = $l_dist;
	          $aim_at = $t;

	  }
         }
    }
   # warn ' Aiming random' if !$aim_at;
    
    return int( rand(2 * pi) ) if !$aim_at;
    
    my $wheel_on = $targets->[ $ball->{n_wheel} ];
    
    my $x_diff = $wheel_on->x - $aim_at->x;
    my $y_diff =  $wheel_on->y - $aim_at->y;

    # calculate angle between vertical down and vector between wheels
         ### tan( theta ) = x_diff / y_diff 
         # theta = atan2 ( x_diff/ y_diff);
    my $angle = rad2deg ( atan2(-$y_diff, $x_diff) + 270);
    $angle -= 360 while $angle > 360;
	
    return ($angle, $aim_at);
}

sub _handle_rotate {
    my ($self, $ball_angle) = @_;
    my $ang = $self->angle();

    #start rotation if we have a angle_diff to handle
    if ( !$self->rotating && abs($ball_angle) != $ang ) {
        # warn ' Not rotating ';
        if ( $ball_angle > $ang ) {
            # warn ' Start Right';
            $self->rotating( 1 ) ;
            return 'R' ;
        }
        elsif ( $ball_angle < $ang ) {
            # warn ' Start Left';
            $self->rotating( -1 ) ;
            return 'L' ; #We rotate left
        }
        else {
            # FIXME: my math sucks at 4am, but
            # won't $pick always be 0 ?
            my $pick = int( rand(1) - rand(1) );
        
            if( $pick > 0 ) {
                $pick = 'R';
                $self->rotating( 1 );
            }
            else {
                $pick = 'L';
                $self->rotating( -1 );
            }
        }
    }
    elsif ( $self->rotating != 0 ) {
        # we were rotating right
        if( $self->rotating == 1 && $ball_angle > $ang ) {
	warn "Continue Right Trying to get to $ball_angle got to $ang"
                if $DEBUG;
            return 'R' #continue rotating
        }
        elsif ( $self->rotating == -1 && $ball_angle  <  $ang ) {
            warn "Continue Left Trying to get to $ball_angle got to $ang"
                if $DEBUG;
            return 'L' #continue rotating
        }
    }
    # shoot if we can't get any closer
    warn "Trying to get to $ball_angle got to $ang" if $DEBUG;
    $self->angle( 0 );
    $self->rotating( 0 );
    $self->timeout( SDL::get_ticks() ); # reset shooting timeout
    return 'S'  #We shoot

}

sub get_next_command {
    my ($self, $ball, $targets) = @_;

    return 'W' unless _attached($ball); # wait to attach onto a ball

    if (!$self->angle) {
        my ($ang) = _get_next_rad($ball, $targets);
        $self->angle ( $ang ) ;
    }

    # release ball if we reached a timeout
    if (SDL::get_ticks() - $self->timeout > 2000) {
        $self->timeout( SDL::get_ticks() );
        return 'S';
    }
    
    #warn ' Going to angle '. $self->angle.' currently at '.$ball->rad ;
   return  $self->_handle_rotate($ball->rad);
}



#Add more AI stuff here later 
#we can do race against computer
#
1; #no not 42 :p
