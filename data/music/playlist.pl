use strict;
use warnings;
use File::Spec;
use threads;
use threads::shared;
use SDL;
use SDL::Mixer;
use SDL::Mixer::Music;
use SDL::Mixer::Effects;
use SDL::Video;
use SDL::Event;
use SDL::Events;
use Carp;


my $background :shared = 0;

# Initing video
#Die here if we cannot make video init
croak 'Cannot init ' . SDL::get_error()
if ( SDL::init( SDL_INIT_AUDIO | SDL_INIT_VIDEO ) == -1 );

my $app = SDL::Video::set_video_mode( 800, 600, 32,
	SDL_HWSURFACE | SDL_DOUBLEBUF | SDL_HWACCEL );


SDL::Mixer::open_audio( 44100, AUDIO_S16, 2, 4096 );

my ($status, $freq, $format, $channels) = @{ SDL::Mixer::query_spec() };

my $audiospec = sprintf("%s, %s, %s, %s\n", $status, $freq, $format, $channels);

carp ' Asked for freq, format, channels ', join( ' ', ( 44100, AUDIO_S16, 2,) );
carp ' Got back status, freq, format, channels ', join( ' ', ( $status, $freq, $format, $channels ) );

my $data_dir = '.';

opendir( my $DIR, $data_dir);
my @musics = readdir($DIR);
my @songs = ();
map { if ($_ =~ /\.ogg/)
{ #print 'Found: '.$_."\n";
push @songs, File::Spec->catfile( $data_dir, $_);
} 
} @musics;


#SDL::Mixer::Music::volume_music( 0 );

my $music_is_playing = 0;
my $callback = sub { 
	SDL::Mixer::Music::halt_music(); 		
	$music_is_playing = 0; 
#	print STDERR 'Going to next song'
};

SDL::Mixer::Music::hook_music_finished(	$callback );

@songs = sort { int( rand(2) - rand(2)) } @songs;

my $event = SDL::Event->new();

sub spiffy
{
	my $channel  = shift;
	my $samples  = shift;
	my $position = shift;
	my @stream   = @_;
	print join("  | ", @stream);
	print "\n";
}

sub spiffydone
{


}


foreach (@songs)
{
	warn 'Playing '.$_  ;
	my $song = SDL::Mixer::Music::load_MUS ( $_);
	my $channel = SDL::Mixer::Music::play_music( $song, 0 );
	my $effect_id = SDL::Mixer::Effects::register($channel, "main::spiffy", "main::spiffydone", 0);

	$music_is_playing = 1;


	while ( $music_is_playing)
	{
		while ( SDL::Events::poll_event($event) )
		{

			if ( $event->type == SDL_QUIT ) {
				exit;
			}
			elsif ( $event->type == SDL_KEYDOWN ) {

				if ( $event->key_sym == SDLK_DOWN ) {
					&$callback();
				}
			}

		}
		SDL::delay(100);
	}

	SDL::Mixer::Effects::unregister($channel, $effect_id);

}

SDL::Mixer::Music::hook_music_finished();

