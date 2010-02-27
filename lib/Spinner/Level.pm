package Spinner::Level;
use Mouse;
use JSON::Any;
use Spinner::Wheel;

has 'wheels'         => ( is => 'rw', isa => 'ArrayRef' );
has 'starting_wheel' => ( is => 'rw', isa => 'Int', default => 1 );
has 'number'         => ( is => 'rw', isa => 'Int', default => 1 );
has 'name'           => ( is => 'rw', isa => 'Str', default => 'unknown' );


sub load {
    my ($self, $app) = @_;

    # levels are stored here
    my $level_number = $self->number;
    return unless $level_number =~ /\d+/o;
    my $filename = "data/levels/$level_number.dat";
    return unless -r $filename;

    # load file into $json...
    open my $fh, '<', $filename 
        or die "error loading file '$filename': $!\n";
    my $json = do { local $/; <$fh> };
    close $fh;

    # ... and then into a hashref
    my $level = JSON::Any->from_json($json);

   $self->name( $level->{name} );
    # load wheels
    my @wheels = ();
    foreach my $wheel_data ( @{$level->{wheels}} ) {
        my $w = Spinner::Wheel->new( %{$wheel_data} );
        $w->init_surface($app);

        push @wheels, $w;
    }
    $self->wheels(\@wheels);
    $self->starting_wheel($level->{starting_wheel});

    return $self;
}

42;
