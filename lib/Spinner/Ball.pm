package Spinner::Ball;
use Mouse;
use Spinner;
use Math::Trig;

has 'x'        => ( is => 'rw', isa => 'Num', default => 0 );
has 'y'        => ( is => 'rw', isa => 'Num', default => 0 );
has 'size'     => ( is => 'ro', isa => 'Int', default => 26 );
has 'rad'      => ( is => 'rw', isa => 'Num', default => 0 );
has 'rotating' => ( is => 'rw', isa => 'Num', default => 0 );
has 'color'     => ( is => 'ro', default => 0xFF0000FF );
has 'n_wheel'   => ( is => 'rw', isa     => 'Int', default => 0 );
has 'old_wheel' => ( is => 'rw', isa     => 'Int', default => 0 );
has 'ready'     => ( is => 'rw', isa     => 'Int', default => 0 )
  ;    #wait until level is ready

has 'surface' => ( is => 'rw', isa => 'SDL::Surface' );

has 'vx' => ( is => 'rw', isa => 'Num', default => 0 );
has 'vy' => ( is => 'rw', isa => 'Num', default => 0 );



sub draw {
    my ( $ball ) = @_;
    my $app = Spinner->app;
    my $size = $ball->size;

    my $new_part_rect = SDL::Rect->new( 0, 0, $size, $size );
    my $centered_rect = SDL::Rect->new( $ball->x - $size / 2,
                                        $ball->y - $size / 2,
                                        $app->w, $app->h);

    #Blit the particles surface to the app in the right location
    SDL::Video::blit_surface($ball->surface, $new_part_rect, $app, $centered_rect);
}

sub update {
    my ($ball, $dt, $particles) = @_;
    my $app = Spinner->app;

    my $ball_radius = $ball->size / 2;

    if ( $ball->n_wheel != -1 ) {    #stuck on a wheel
        my $wheel = $particles->[ $ball->n_wheel ];
        return 0 unless $wheel;

        # Rotate the ball on the wheel
        if ( $ball->rotating != 0 ) {
            my $angle = $ball->rad + $dt * $wheel->speed * $ball->rotating;
            $ball->rad( $angle - ( int( $angle / 360 ) * 360 ) );
        }
        $ball->x( $wheel->x +
              sin( $ball->rad * pi / 180 ) * ( $wheel->size / 2 + 11 ) );
        $ball->y( $wheel->y +
              cos( $ball->rad * pi / 180 ) * ( $wheel->size / 2 + 11 ) );

        # the first time we get not ready and a wheel
        $ball->ready(1) unless $ball->ready;
    }
    else {
        $ball->x( $ball->x + $ball->vx * $dt );
        $ball->y( $ball->y + $ball->vy * $dt );

        # Bounce our velocities components if we are going off the screen
        if (   $ball->x > ( $app->w - $ball_radius ) && $ball->vx > 0
            || $ball->x < (       0 + $ball_radius ) && $ball->vx < 0 )
        {
            # if we bounce, we can go back to the previous wheel
            $ball->old_wheel(-1);
            $ball->vx( $ball->vx * -1 );
            return 1;
        }
        if (   $ball->y > ( $app->h - $ball_radius ) && $ball->vy > 0
            || $ball->y < (       0 + $ball_radius ) && $ball->vy < 0 )
        {
            # if we bounce, we can go back to the previous wheel
            $ball->old_wheel(-1);
            $ball->vy( $ball->vy * -1 );
            return 1;
        }

 
       for ( 0 .. $#$particles ) {
            # don't collide with previous wheel
            next if $_ == $ball->old_wheel;

            # Check if our mouse rectangle collides with the particle's rectangle
            my $p                 = $particles->[$_];
            my $wheel_radius      = $p->size / 2;
            my $x_diff            = $ball->x - $p->x;
            my $y_diff            = $ball->y - $p->y;
            my $distance_squared  = $x_diff * $x_diff + $y_diff * $y_diff;
            my $sum_radii_squared = ($ball_radius + $wheel_radius) ** 2;

            my $angle  = atan2(-$y_diff, $x_diff) * 180 / pi;
            $angle += 360 if $angle < 0;

            if ($distance_squared <= $sum_radii_squared) {
              
                $ball->rad($angle + 90);
                $ball->n_wheel($_);

                push @{$ball->{visited}}, $_;
               # warn $#{$ball->{visited}} + 1;
              #  warn $#$particles ;
                return 3 if $#$particles == $#{$ball->{visited}} + 1;
                return 2;
            }
         _gravity ( $p, $ball, $angle, $x_diff, 
                    $y_diff, $distance_squared, $dt
                  ) if( $p->gravity > 0);
        }
    }
    return 0;
}

#
# New subroutine "_gravity" extracted - Sun Feb 28 21:57:30 2010.
#
sub _gravity {
    my ($p, $ball, $angle, $x_diff, $y_diff, $distance_squared, $dt) = @_;

    #warn  $ball->x, ' ', $ball->y; #<--- Can't call method "x" on an undefined value at (eval 692) line 11.
#       warn  $p->x, ' ', $p->y;
    my $px = my $py = 1;

    $px = $x_diff > 0 ? -1 
           : $x_diff < 0 ?  1
           : 0
           ;

     $py = $y_diff > 0 ? -1 
           : $y_diff < 0 ?  1
           : 0
           ;
   
    my $G = 0.06; 
    
    my $v_G = $G * (  $p->gravity * $dt  / $distance_squared );
    
    my $v_Gx = $px * $v_G;
    my $v_Gy = $py * $v_G;

    $ball->vx ( $ball->vx +  $v_Gx );
    $ball->vy ( $ball->vy +  $v_Gy );
    return ($G, $px, $py);
}

42;
