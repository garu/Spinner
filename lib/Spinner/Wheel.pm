package Spinner::Wheel;
use Mouse;
use SDL;
use SDL::Image;
use SDL::Video;
use SDL::Surface;
use SDL::GFX::Primitives;


has 'x'       => ( is => 'ro', isa => 'Int', required => 1 );
has 'y'       => ( is => 'ro', isa => 'Int', required => 1 );
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

    if ( $size == 60) {
        SDL::Video::blit_surface(
            $self->image, SDL::Rect->new( 0, 0, $self->image->w, $self->image->h ),
            $surface,     SDL::Rect->new( 0, 0, $surface->w,     $surface->h )
        );

    }
    SDL::GFX::Primitives::aacircle_color( $surface, $size / 2, $size / 2,
	      $size / 2 - 2, 0x000000FF );

     SDL::GFX::Primitives::aacircle_color( $surface, $size / 2, $size / 2,
	        $size / 2 - 1, 0x000000FF );

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
