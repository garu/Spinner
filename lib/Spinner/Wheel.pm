package Spinner::Wheel;
use Mouse;

has 'x'       => ( is => 'ro', isa => 'Int', required => 1 );
has 'y'       => ( is => 'ro', isa => 'Int', required => 1 );
has 'size'    => ( is => 'ro', isa => 'Int', default => 60 );
has 'color'   => ( is => 'rw', default => undef );
has 'visited' => ( is => 'rw', default => undef );

has 'surface' => ( is => 'rw', isa => 'SDL::Surface' );

has 'speed' => ( is  => 'rw', isa => 'Num',
              default => sub { return 0.3 + rand(0.3) } #return rand(0.7) + 0.3 }
            );

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

42;
