use strict;
use warnings;
use File::Spec;
use threads;
use threads::shared;
use SDL;
use SDL::Rect;
use SDL::Surface;
use SDL::Mixer;
use SDL::Mixer::Music;
use SDL::Mixer::Effects;
use SDL::Video;
use SDL::Event;
use SDL::Events;
use Carp;

my $background : shared = 0;

# Initing video
#Die here if we cannot make video init
croak 'Cannot init ' . SDL::get_error()
  if ( SDL::init( SDL_INIT_AUDIO | SDL_INIT_VIDEO ) == -1 );

my $app = SDL::Video::set_video_mode( 800, 600, 32,
    SDL_HWSURFACE | SDL_DOUBLEBUF | SDL_HWACCEL );

SDL::Mixer::open_audio( 44100, AUDIO_S16, 2, 1024 );

my ( $status, $freq, $format, $channels ) = @{ SDL::Mixer::query_spec() };

my $audiospec =
  sprintf( "%s, %s, %s, %s\n", $status, $freq, $format, $channels );

carp ' Asked for freq, format, channels ',
  join( ' ', ( 44100, AUDIO_S16, 2, ) );
carp ' Got back status, freq, format, channels ',
  join( ' ', ( $status, $freq, $format, $channels ) );

my $data_dir = '.';

opendir( my $DIR, $data_dir );
my @musics = readdir($DIR);
my @songs  = ();
map {
    if ( $_ =~ /\.ogg/ )
    {    #print 'Found: '.$_."\n";
        push @songs, File::Spec->catfile( $data_dir, $_ );
    }
} @musics;

#SDL::Mixer::Music::volume_music( 0 );

my $music_is_playing = 0;
my $callback         = sub {

    $music_is_playing = 0;

    #	print STDERR 'Going to next song'
};

SDL::Mixer::Music::hook_music_finished($callback);

@songs = sort { int( rand(2) - rand(2) ) } @songs;

my $event = SDL::Event->new();

my $process_thread;
my $stream_update : shared = 0;
my $stream : shared;
my $quit_processing : shared = 0;

foreach (@songs) {
    warn 'Playing ' . $_;
    my $song = SDL::Mixer::Music::load_MUS($_);
    SDL::Mixer::Music::play_music( $song, 0 );
    my $effect_id =
      SDL::Mixer::Effects::register( MIX_CHANNEL_POST, "main::spiffy",
        "main::spiffydone", 0 );

    $music_is_playing = 1;

    while ($music_is_playing) {
        
        while ( SDL::Events::poll_event($event) ) {
         

            if ( $event->type == SDL_QUIT ) {
                SDL::Mixer::Music::halt_music();
                join_threads();
                exit;
            }
            elsif ( $event->type == SDL_KEYDOWN ) {

                if ( $event->key_sym == SDLK_DOWN ) {
                    &$callback();
                }
            }
           
        }

    # $stream update is a mutex so we don't slow the music down
       $process_thread = threads->create( 'process_stream', '' ) if !$process_thread;

       

        SDL::delay(100);
        
    }

    SDL::Mixer::Effects::unregister( MIX_CHANNEL_POST, $effect_id );

}

SDL::Mixer::Music::hook_music_finished();
join_threads();

sub spiffy {
    my $channel  = shift;
    my $samples  = shift;
    my $position = shift;
    my @stream   = @_;

    #print "\n";
    if ( !$stream_update ) {
        $stream = join ',', @stream;
        $stream_update = 1;

    }
    return @stream;
}

sub spiffydone {

    #print @_;
    print "spiffy done \n";
}

sub process_stream {

  
    while (!$quit_processing) {
        if ( $stream_update ) {
            SDL::Video::fill_rect($app, SDL::Rect->new(0, 0, 800, 600), 
                               SDL::Video::map_RGB($app->format(), 0, 0, 0));
            my @stream_cut = split( ',', $stream );
            $stream = '';
            my @left;
            my @right;
            for ( my $i = 0 ; $i < $#stream_cut ; $i += 2 ) {

               my $left = $stream_cut[$i];
               my $right = $stream_cut[ $i + 1 ];
               
              my $point_y = ( ( ($left ) ) * 150/32000 ) + 300 ;
              my $point_y_r = ( ( ($right ) ) * 150/32000 ) + 300 ;
              my $point_x = ($i / $#stream_cut) *  800;
              my $point_x_r = ($i / $#stream_cut) *  800;
              
             # print int($point_y) .'|'. int($point_x)."\n";
             
             SDL::Video::fill_rect($app, 
                       SDL::Rect->new($point_x, $point_y, 
                                     1, 1), SDL::Video::map_RGB($app->format(), 0, 0, 255));
             SDL::Video::fill_rect($app, 
                       SDL::Rect->new($point_x_r, $point_y_r, 
                                     1, 1), SDL::Video::map_RGB($app->format(), 255, 0, 0));
                                     

              
             

            }
            $stream_update = 0;
             SDL::Video::flip( $app );
        }
        else
        {
                SDL::delay(10);
        }
        
       
        
    }

    # return ($i, \@left, \@right, \@stream);
}

sub join_threads {

   # print 'Waiting for thread to finish ...'
   if ($process_thread)
   {
    $quit_processing = 1;
    $process_thread->join();
    
   }

}


 
                
