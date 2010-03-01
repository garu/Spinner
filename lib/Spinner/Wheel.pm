package Spinner::Wheel;
use Mouse;
use SDL;
use SDL::Image;
use SDL::Video;
use SDL::Surface;
use SDL::GFX::Primitives;


has 'x'       => ( is => 'rw', isa => 'Num', required => 1 );
has 'y'       => ( is => 'rw', isa => 'Num', required => 1 );

has 'size'    => ( is => 'ro', isa => 'Int', default => 60 );
has 'color'   => ( is => 'rw', default => undef );
has 'visited' => ( is => 'rw', isa => 'Bool', default => undef );
has 'image'   => ( is => 'ro', isa => 'SDL::Surface',
                   default => sub { SDL::Image::load('data/wheel.png') }
                 );

has 'surface' => ( is => 'rw', isa => 'SDL::Surface' );

has 'speed' => ( is  => 'rw', isa => 'Num',
              default => sub { return 0.3 + rand(0.3) } #return rand(0.7) + 0.3 }
            );
has 'gravity' => ( is => 'rw', isa => 'Int', default => -1 );

has 'patrol'  => ( is => 'ro', isa => 'ArrayRef', default => sub {[] } );


# Blit the particles surface to the app in the right location
sub draw {
    my ($self, $app) = @_;

    my $new_part_rect = SDL::Rect->new( 0, 0, $self->size, $self->size );

    SDL::Video::blit_surface(
        $self->surface,
        $new_part_rect,
        $app,
        SDL::Rect->new(
            $self->x - ( $self->size / 2 ), $self->y - ( $self->size / 2 ),
            $app->w, $app->h
        )
    );
}

sub update
{
    my ( $dt, $particles, $app) = @_;
    foreach my $p (@{$particles}) { $p->patrol_up($dt)} ;

}

sub patrol_up
{
	my ($self, $dt) = @_;


	my @patrol_loc = @{$self->patrol()};
	return if ($#patrol_loc < 0);
	# keep a copy of the  start position we  go back to it
	($self->{sx} , $self->{sy} ) = ($self->x , $self->y)  if (!$self->{sx} && !$self->{sy});

#	warn 'Start at '. $self->{sx}. ' ' . $self->{sy};
	$self->{patrol_to} = 0 if !$self->{patrol_to} ;

	my $get_to;
	 if ( $self->{patrol_to} < 0)
	 {
		 $get_to =  { x => $self->{sx}, y => $self->{sy}  };	

	 }
	 else
	 {
		$get_to = $patrol_loc[ $self->{patrol_to} ] ;

	 }


#	warn 'Trying to get_to '. $get_to->{x}. ' ' . $get_to->{y};

	my $x_diff = $self->x - $get_to->{x};
	my $y_diff = $self->y - $get_to->{y};
#	warn 'To get_to '. $x_diff. ' ' . -$y_diff;


	my $next_tick = $dt * $self->speed; 

 	if  (  abs($x_diff) < $next_tick && abs($y_diff) < $next_tick) #if we are going to be at the place snap int and  increment patrol_to
	{
		$self->x( $get_to->{x});
		$self->y( $get_to->{y});
		$self->{patrol_to} += 1; 
		
		$self->{patrol_to} = -1 if  !($patrol_loc[ $self->{patrol_to} ]); 
#		die 'Patrolling back to '.  $self->{patrol_to};
		return
	}

	my $xd = my $yd = 1;
	$xd = -1 if $x_diff > 0;
	$yd = -1 if $y_diff > 0;


	$self->x ( $self->x + ( $next_tick * $xd) ) ;#if $x_diff > $next_tick;
	$self->y ( $self->y + ( $next_tick * $yd) ) ;#if $y_diff > $next_tick;




}

sub init_surface {
    my ($self, $app) = @_;
    my ( $size, $color ) = ($self->size, $self->color);

    #make a surface based on the size
    my $surface = SDL::Surface->new(
            SDL_SWSURFACE, $size + 15, $size + 15, 32, 0, 0, 0, 255 );

    SDL::Video::fill_rect(
        $surface,
        SDL::Rect->new( 0, 0, $size + 15, $size + 15 ),
        SDL::Video::map_RGB( $app->format, 60, 0, 0 )
    );

    #draw a circle on it with a random color
    SDL::GFX::Primitives::filled_circle_color(
        $surface, $size / 2, $size / 2,
        $size / 2 - 2,
        $color || rand_color(),
    );
    SDL::Video::display_format($surface);
    my $pixel = SDL::Color->new( 60, 0, 0);
    SDL::Video::set_color_key( $surface, SDL_SRCCOLORKEY, $pixel );

    my $ring = 0x000000FF;
   
    if ( $color ) {
	$ring = 0xFF0000FF;
    }
        SDL::Video::blit_surface(
            $self->image, SDL::Rect->new( 0, 0, $self->image->w, $self->image->h ),
            $surface,     SDL::Rect->new( 0, 0, $surface->w,     $surface->h )
        );

    
    SDL::GFX::Primitives::aacircle_color( $surface, $size / 2, $size / 2,
	      $size / 2 - 2, $ring);

     SDL::GFX::Primitives::aacircle_color( $surface, $size / 2, $size / 2,
	        $size / 2 - 1, $ring );

    $self->surface($surface);
}

#Gets a random color for our particle
sub rand_color {
    my $r = rand( 0x100 - 0x44 ) + 0x44;
    my $b = rand( 0x100 - 0x44 ) + 0x44;
    my $g = rand( 0x100 - 0x44 ) + 0x44;
    my $a = rand( 0x100 - 0x44 ) + 0x44;
    return ( $a | ( $r << 24 ) | ( $b << 16 ) | ($g) << 8 );
}


42;
