#!/usr/bin/perl 
###############################################################################
#          FILE:   pimpd.pl
#         USAGE:  ./pimpd.pl
#   DESCRIPTION:  Perl Interface for the Music Player Daemon
#        AUTHOR:  trapd00r (trapd00r at trapd00r dot se)
#       VERSION:  0.9.7
#       CREATED:  2010-01-09 09:29:44 AM
#       UPDATED:  2010-03-09 07:45:44 AM
###############################################################################

use strict;
use Audio::MPD;
use File::Copy;
use LWP::Simple;
use HTML::TokeParser::Simple;
use Text::Wrap;
use List::Util qw(shuffle);
use Pod::Usage;
use Getopt::Long;

require "$ENV{'XDG_CONFIG_HOME'}/pimpd/config.pl";
our ($basedir, $playlist_dir, $portable,
     $remote_host, $remote_pass, $remote_user);

my $APPLICATION_NAME    = 'pimpd';
my $APPLICATION_VERSION = '0.9.7';

my $mpd;
if(defined($remote_host)) {
  $mpd = Audio::MPD->new(host     =>  $remote_host,
                         password =>  $remote_pass,
                         );
}
else {
  $mpd = Audio::MPD->new;
}

our ($nocolor); #FIXME

my @clr = ("\033[31m", "\033[31;1m", "\033[32m", "\033[32;1m", "\033[33m",
           "\033[34m", "\033[34;1m", "\033[36m", "\033[36;1m", "\033[0m");

my $notag        = $clr[0].'undef'.$clr[9]; 
my $curr_artist  = $mpd->current->artist  // $notag;
my $curr_album   = $mpd->current->album   // $notag;
my $curr_title   = $mpd->current->title   // $notag;
my $curr_genre   = $mpd->current->genre   // $notag;
my $curr_file    = $mpd->current->file;
my $curr_date    = $mpd->current->date    // $notag;
my $curr_rate    = $mpd->status->bitrate  // $notag;
my $stat_artists = $mpd->stats->artists;
my $stat_albums  = $mpd->stats->albums;
my $stat_songs   = $mpd->stats->songs;
my $status_rep   = $mpd->status->repeat;
my $status_rnd   = $mpd->status->random;

if(!@ARGV) {
  &help;
}
GetOptions(information   =>  \&information,
           randomize     =>  \&randomize,
           copy          =>  \&cp2port,
           favorite      =>  \&favlist,
           listalbums    =>  \&listalbums,
           show          =>  \&show_playlist,
           play          =>  \&play_song_from_pl,
           add           =>  \&add_playlist,
           monitor       =>  \&monitoring,
           lyrics        =>  \&lyrics,
           nocolor       =>  \$nocolor,

           help          =>  \&help,
           bighelp       =>  \&bighelp,
           );

sub information {
  if($curr_rate < 192) {
    $curr_rate = $clr[0].$curr_rate.$clr[9];
  }
  
  # We're truncating lines that'll span over 80 columns. 80-14=66.
  printf("$clr[6]P$clr[9]   %8s %.66s \n", 'Artist:', $curr_artist); 
  printf("$clr[6]L$clr[9]   %8s %.66s \n", 'Album:', $curr_album);
  printf("$clr[6]A$clr[9]   %8s %.66s \n", 'Song:', $curr_title);
  printf("$clr[6]Y$clr[9]   %8s %.66s \n", 'Genre:', $curr_genre);
  printf("$clr[6]I$clr[9]   %8s %.66s \n", 'File:', $curr_file);
  printf("$clr[6]N$clr[9]   %8s %.66s \n", 'Year:', $curr_date);
  printf("$clr[6]G$clr[9]   %8s %.66s \n", 'Bitrate:', $curr_rate);
  print "\n";
  printf("$clr[8]S$clr[9]   %8s %.66s \n", 'Repeat:', $status_rep);
  printf("$clr[8]T$clr[9]   %8s %.66s \n", 'Shuffle:', $status_rnd);
  printf("$clr[8]A$clr[9]   %8s %.66s \n", 'Songs:', $stat_songs);
  printf("$clr[8]T$clr[9]   %8s %.66s \n", 'Albums:', $stat_albums);
  printf("$clr[8]S$clr[9]   %8s %.66s \n", 'Artists:', $stat_artists);

  exit 0;

}

sub randomize {
  my $count = $ARGV[0] // 100;
  my @songs = $mpd->collection->all_pathes;
  @songs    = shuffle(@songs);
  $mpd->playlist->clear;
  $mpd->playlist->add(@songs[0 .. $count-1]);
  $mpd->random(1);
  $mpd->repeat(1);
  $mpd->play;
  my $message = "Added $count random songs:\n\n";
  &show_playlist($message);
  exit 0;
}

sub show_playlist {
  my $header = shift;
  if($header eq 'show') {
    $header = "Playlist:\n";
  }

  my @playlist = $mpd->playlist->as_items;
  my $i        = -1;  
  
  print $header;
  printf("%29s %6s\n", 'ARTIST', 'SONG');
  foreach my $song(@playlist) {
    my $title  = $song->title  // 'undef';
    my $album  = $song->album  // 'undef';
    my $artist = $song->artist // 'undef';
#=== titlecase
    $title  =~ s/(\w+)/\u\L$1/g;
    $album  =~ s/(\w+)/\u\L$1/g;
    $artist =~ s/(\w+)/\u\L$1/g;
    ++$i;
    
    # 80 columns
    printf"%03i $clr[5]%25.25s $clr[9]| $clr[1]%-47.47s $clr[9] \n",
          $i,$artist, $title;
  }
#== Which track was chosen to start with?
  printf("\n$clr[1]NOW$clr[9]: $clr[5]%0s $clr[9]%0s $clr[1]%0s$clr[9]\n",
         $mpd->current->artist, $mpd->current->album, $mpd->current->title);
  exit 0;
}

sub add_playlist {
  if(@ARGV) {
    my $playlist = $ARGV[0];
    $mpd->playlist->clear;
    $mpd->playlist->load($playlist);
    $mpd->play;
  }
  else {
    my @playlists = $mpd->collection->all_playlists;
    print "Available playlists: \n\n";
    foreach my $playlist(sort(@playlists)) {
      print $playlist, "\n";
    }
  }
  exit 0;
}

sub scp($$$$) {
  return scp_module(@_) if eval("require Net::SCP;");
  return scp_binary(@_) if -x `which scp`;
  print STDERR 'Failure: No suitable way to transfer file';

  exit 0;
}

sub scp_module {
  require Net::SCP;
  my $host = shift;
  my $src  = shift;
  my $dest = shift;

  $src  =~ s/([ '"&;|])/\\$1/g;
  $dest =~ s/([ '"&;|])/\\$1/g;
  print $dest, $src =~ /^.*\/(.*)$/, "\n";

  my $scp = Net::SCP->new($host, $remote_user);
  $scp->get($src, $dest) || die $scp->{errstr};

  exit 0;
}

sub scp_binary {
  my $host = shift;
  my $src  = shift;
  my $dest = shift;

  $src  =~ s/([ '"&;|])/\\$1/g;
  $dest =~ s/([ '"&;|])/\\$1/g;
  `/usr/bin/scp '$host:$src' '$dest'`;
  
  exit 0;
}

sub cp2port {
  my $dir  = $ARGV[0] // $portable;
  my $file = $mpd->current->file;
  if(defined($remote_host)) {
    return scp1($remote_host, $basedir.$file, $dir);
  }
  chomp($file);
  copy($basedir.$file, $dir) || die "Failure: $! \n";

  exit 0;
}

sub favlist {
  my $playlist = $ARGV[0] // lc($mpd->current->genre) // 'random';
  my $filepath = $mpd->current->file;
  my $fullpath = "$playlist_dir/$playlist";
  open PLAYLIST, ">>$fullpath\.m3u" || die "$!";
  print PLAYLIST $filepath, "\n";
  close PLAYLIST;
  print $clr[1].$filepath,$clr[9].' >> ',$clr[3]."$fullpath\.m3u",$clr[0], "\n";

  exit 0;
}

sub listalbums {
  my $artist = $ARGV[0] // $mpd->current->artist;
  my @albums = sort($mpd->collection->albums_by_artist($artist));
  print "$clr[1]$artist$clr[9] is featured on:\n\n";
  foreach my $album(@albums) {
    print $album, "\n";
  }
  exit 0;
}

sub play_song_from_pl {
  my $choice = $ARGV[0];
  $mpd->play($choice);
  printf("$clr[1]%0s $clr[3]%0s $clr[5]%0s $clr[9] \n",
         $mpd->current->artist, $mpd->current->album, $mpd->current->title);
  exit 0;
}

sub lyrics {
  my $url = "http://lyricsplugin.com/winamp03/plugin/?artist=".
            "$curr_artist&title=$curr_title";
  my $lyrics = get($url);
  my $p      = HTML::TokeParser::Simple->new(string=>$lyrics);

  my @lyrics;
  while(my $token = $p->get_token) {
    next unless($token->is_text);
    push(@lyrics, $token->as_is);
  }
  $Text::Wrap::columns = 80;
  print wrap('', '', @lyrics[12..@lyrics-13]);
  exit 0;
}

sub monitoring {
  my $np = "";
  while(1) {
    my $current = $mpd->current // undef;
    my $file;
    if(!$current) {
      $file = 'undef';
    }
    else {
      $file = $mpd->current->file;
    }
    my @date = localtime(time);
    my @colors = shuffle(@clr);

    if(!$current) {
      $current = 'undef';
    }
    if("$np" ne "$current") {
      $np = $current;
      printf("%02s:%02s:%02s |%0s %.68s %0s\n",
             $date[2], $date[1], $date[0], $colors[0], $file, $clr[9]);
    }
    sleep 2;
  }
  exit 0;
}
sub help {
  print << "HELP";
  $APPLICATION_NAME $APPLICATION_VERSION
  Usage: $0 [OPTIONS] (ARGUMENT)

  OPTIONS:
    -i  | --info           print current information
    -r  | --randomize  (I) randomize a new playlist with I tracks. One thousand
                           tracks is the default value
    -c  | --copy [S]       copy the current track to location S
    -f  | --favorite   (S) favorize the current track. If no name for the
                           playlist is given, the 'genre' id3-tag is used
    -l  | --listalbums (S) list all albums by S or the current artist
    -s  | --show           show current playlist
    -p  | --play       [I] play number I track in playlist
    -a  | --add        (S) add S playlist and play it
    -m  | --monitor        monitor MPD for song changes, output on STDOUT
    -ly | --lyrics         show lyrics for the current song

    -h  | --help           show this help
    -b  | --bighelp        show The Big Help
  Arguments:
    I  Integer value 
    S  String  value
    [] Mandantory
    () Optional
  
  Note that all options can be specified using 'lazy' shortcuts.
  This is all the same: -ly -lyr --lyri --lyrics
HELP
exit 0;
}
