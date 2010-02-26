package Spinner::Ball;
use Mouse;

has 'x'       => ( is => 'rw', isa => 'Num', default => 0  );
has 'y'       => ( is => 'rw', isa => 'Num', default => 0  );
has 'size'    => ( is => 'ro', isa => 'Int', default => 25 );
has 'rad'     => ( is => 'rw', isa => 'Num', default => 0  );
has 'color'   => ( is => 'ro', default => 0xFF0000FF );
has 'n_wheel' => ( is => 'rw', isa => 'Int', default => 0  );
has 'old_wheel' => ( is => 'rw', isa => 'Int', default => 0  );

has 'surface' => ( is => 'rw', isa => 'SDL::Surface' );

has 'vx' => ( is  => 'rw', isa => 'Num', default => 0 );
has 'vy' => ( is  => 'rw', isa => 'Num', default => 0 );

sub draw {
    my ($ball, $app) = @_;

    my $new_part_rect = SDL::Rect->new( 0, 0, 26, 26 );

    if($ball->n_wheel != -1) {
        # sin(rad) = opposite / hypo
        my $x2 = my $y2 = 0;
        my $xD = -1 ;my $yD = 1;
        $yD = -1 if $ball->rad < 270 && $ball->rad > 90;
        $xD = 1  if $ball->rad < 180 && $ball->rad > 0;
        $x2 = ($ball->x + 12 * $xD ) + (70 * sin ( $ball->rad * 3.14/180 ) );
        $y2 = ($ball->y + 12 * $yD ) + (70 * cos ( $ball->rad * 3.14/180 ) );

        SDL::GFX::Primitives::aaline_RGBA( $app, $ball->x,  $ball->y, $x2, $y2, 23, 244, 45, 244 );
    }

    #Blit the particles surface to the app in the right location
    SDL::Video::blit_surface(
        $ball->surface,
        $new_part_rect,
        $app,
        SDL::Rect->new(
            $ball->x - ( 26 / 2 ), $ball->y - ( 26 / 2 ),
            $app->w, $app->h
        )
    );
}

sub update {
    my $ball = shift;
    my $dt = shift;
    my $particles = shift;
    my $app = shift;

    if ( $ball->n_wheel != -1 ) {   #stuck on a wheel
        my $wheel = $particles->[ $ball->n_wheel ];
        return unless $wheel;

        $ball->rad( ($ball->rad + $dt * $wheel->speed) % 360 );    #rotate the ball on the wheel

        $ball->x( $wheel->x + sin( $ball->rad * 3.14 / 180 ) * ( $wheel->size / 2 + 8 ));
        $ball->y( $wheel->y + cos( $ball->rad * 3.14 / 180 ) * ( $wheel->size / 2 + 8 ));

    }
    else {
        $ball->x( $ball->x + $ball->vx * $dt);
        $ball->y( $ball->y + $ball->vy * $dt);

        # Bounce our velocities components if we are going off the screen
        if ( ( $ball->x > ( $app->w - (13) ) && $ball->vx > 0 ) || ($ball->x < ( 0 + (13) ) && $ball->vx < 0) )
        {
            # if we bounce, we can go back to the previous wheel
            $ball->old_wheel( -1 );
            $ball->vx( $ball->vx * -1);
        }
        if ( ( $ball->y > ( $app->h - (13) ) && $ball->vy > 0) || ( $ball->y < ( 0 + (13) ) && $ball->vy < 0) )
        {
            # if we bounce, we can go back to the previous wheel
            $ball->old_wheel( -1 );
            $ball->vy( $ball->vy * -1 );
        }

        foreach ( 0 .. $#{$particles} ) {

            # don't collide with previous wheel
            next if $_ == $ball->old_wheel;

            my $p = @{$particles}[$_];

           # Check if our mouse rectangle collides with the particle's rectangle
            my $rad = ( $p->size / 2 ) + 10;
            if (   ( $ball->x < $p->x + $rad )
                && ( $ball->x > $p->x - $rad )
                && ( $ball->y < $p->y + $rad )
                && ( $ball->y > $p->y - $rad ) )
            {
                #We got that sucker!!
                #Get rid of the particle for us
                $ball->n_wheel( $_ );

                # We are done no more particles left lets get outta here
                #return if $#{$particles} == -1;
            }
        }
    }
    return 1;
}

42;
