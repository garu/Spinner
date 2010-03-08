package Spinner::Level;
use Mouse;
use JSON::Any;
use Spinner::Wheel;

has 'wheels'         => ( is => 'rw', isa => 'ArrayRef' );
has 'starting_wheel' => ( is => 'rw', isa => 'Int', default => -1 );
has 'number'         => ( is => 'rw', isa => 'Int', default => 1 );
has 'name'           => ( is => 'rw', isa => 'Str', default => 'unknown' );

sub randomize {
    my $self = shift;
    my @levels = glob('data/levels/*.dat');
    $self->number( int( rand @levels ) + 1);
    return $self;
}

sub load {
    my ($self ) = @_;

    # levels are stored here
    my $level_number = $self->number;
    return unless $level_number =~ /\d+/o;

    my $filename = "data/levels/$level_number.dat";
    my $level = Spinner::load_data_file($filename);
    return unless $level;

    $self->name( $level->{name} );
    # load wheels
    my @wheels = ();
    foreach my $wheel_data ( @{$level->{wheels}} ) {
        my $w = Spinner::Wheel->new( %{$wheel_data} );
        $w->init_surface;

        push @wheels, $w;
    }
    $self->wheels(\@wheels);
    $self->starting_wheel($level->{starting_wheel});

    return $self;
}

42;
