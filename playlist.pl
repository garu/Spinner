use strict;
use warnings;
use File::Spec;
use threads;
use threads::shared;
use SDL;
use SDL::Mixer;
use SDL::Mixer::Music;
#use SDL::Video;
use SDL::Event;
use SDL::Events;
use Carp;


# Initing video
#Die here if we cannot make video init
croak 'Cannot init ' . SDL::get_error()
if ( SDL::init( SDL_INIT_VIDEO | SDL_INIT_AUDIO ) == -1 );

#my $app = SDL::Video::set_video_mode( 800, 600, 32,
#	                    SDL_HWSURFACE | SDL_DOUBLEBUF | SDL_HWACCEL );
		     

SDL::Mixer::open_audio( 44100, AUDIO_S16, 2, 4096 );

my ($status, $freq, $format, $channels) = @{ SDL::Mixer::query_spec() };

my $audiospec = sprintf("%s, %s, %s, %s\n", $status, $freq, $format, $channels);

carp ' Asked for freq, format, channels ', join( ' ', ( 44100, AUDIO_S16, 2,) );
carp ' Got back status, freq, format, channels ', join( ' ', ( $status, $freq, $format, $channels ) );

my $data_dir = '.';

opendir( my $DIR, $data_dir);
my @musics = readdir($DIR);
my @mp3 = ();
map { if ($_ =~ /\.mp3/)
{ #print 'Found: '.$_."\n";
push @mp3, File::Spec->catfile( $data_dir, $_);
} 
} @musics;


my $music_is_playing :shared = 0;
my $callback = sub { SDL::Mixer::Music::halt_music(); 		
 $music_is_playing = 0; carp 'Next song'};

SDL::Mixer::Music::hook_music_finished(	$callback );

foreach ( @mp3)
{
	warn 'Playing '.$_;
	my $song = SDL::Mixer::Music::load_MUS ( $_ );
	SDL::Mixer::Music::play_music( $song, 0 );
	my $music_is_playing = 1;

	while ( $music_is_playing)
	{
		#chop (my $quit = <STDIN>);
		#exit if $quit =~ /q/;
		#if ( $quit =~ /n/ )
		#{
		#SDL::Mixer::Music::halt_music(); 		
		# warn $music_is_playing--;
		#}

		SDL::delay(100);
	}

}

SDL::Mixer::Music::hook_music_finished();
#		while ( SDL::Events::poll_event($event) )
#		{
		#
		#	if ( $event->type == SDL_QUIT ) {
		#		exit;
		#	}
		#	elsif ( $event->type == SDL_KEYDOWN ) {
		#
		#		if ( $event->key_sym == SDLK_DOWN ) {
		#		}
		#	}

		#}

