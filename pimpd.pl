#!/usr/bin/perl
use strict;
# pimpd - Perl Interface for the Music Player Daemon
# Copyright (C) 2010 trapd00r <trapd00r@trapd00r.se>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
###############################################################################
# External modules that'll be used later on
# LWP::Simple, HTML::TokeParser::Simple, Text::Autoformat

my $APPLICATION_NAME    = 'pimpd';
my $APPLICATION_VERSION = '1.4';
my $DEBUG = 0;

use Audio::MPD;
use List::Util qw(shuffle);
use Pod::Usage;
use Getopt::Long;

if(!@ARGV) {
  &help;
}

if($DEBUG eq 1) {
  require "config.pl";
}
else {
  eval {require "$ENV{'XDG_CONFIG_HOME'}/pimpd/pimpd.conf";};
    if($@) {
      require "/etc/pimpd.conf";
    }
    else {
      require "$ENV{'XDG_CONFIG_HOME'}/pimpd/pimpd.conf";
    }
}


# imported variables from the config file
our ($basedir, $playlist_dir, $fallback_playlist, $portable,
     $remote_host, $remote_pass, $remote_user, $history_playlist,
     $opt_color, @clr, $daemon_cmd);


my $mpd;
if(defined($remote_host)) {
  $mpd = Audio::MPD->new(host     =>  $remote_host,
                         password =>  $remote_pass,
                         );
}
else {
  $mpd = Audio::MPD->new;
}

our (@opt_queue, $opt_ctrl, @opt_listExternal,
     $opt_searchPlaylist, $opt_searchDatabase, $opt_information, #FIXME
     $opt_randomize, @opt_addPlaylist, $opt_showPlaylist,
     $opt_favlist, $opt_playSongFromList, $opt_monitoring, $opt_listAlbums,
     $opt_currentlyPlaying, $opt_searchAlbum, $opt_searchArtist,
     $opt_searchTitle, $opt_monitor_d,
     );


# :{,} == zero or more
GetOptions('information'        =>  \$opt_information,
           'np'                 =>  \$opt_currentlyPlaying,
           'randomize:i'        =>  \$opt_randomize,
           'copy'               =>  \&cptoPort,
           'favorite'           =>  \$opt_favlist,
           'listalbums'         =>  \$opt_listAlbums,
           'show'               =>  \$opt_showPlaylist,
           'play'               =>  \$opt_playSongFromList,
           'add=s{1,}'          =>  \@opt_addPlaylist,
           'monitor'            =>  \$opt_monitoring,
           'md|monitord'        =>  \$opt_monitor_d, 
           'queue=i{1,}'        =>  \@opt_queue,
           'lyrics'             =>  \&lyrics,
           'ctrl'               =>  \$opt_ctrl,
           'external=s{1,}'     =>  \@opt_listExternal,                          
           'spl|search-pl=s'    =>  \$opt_searchPlaylist,
           'sdb|search-db=s'    =>  \$opt_searchDatabase,
           'sal|search-album=s' =>  \$opt_searchAlbum,
           'sar|search-artist=s'=>  \$opt_searchArtist,
           'set|search-title=s' =>  \$opt_searchTitle,
           'no-color|nocolor'   =>  \$opt_color,

           'help'               =>  \&help,
           );

if($opt_color) {
  @clr = ("\033[0m");
}

if($mpd->status->playlistlength < 1) {
  # if the user did the right thing here, we'll let her
  unless($opt_randomize      or
         $opt_searchDatabase or
         $opt_searchAlbum    or
         $opt_searchArtist   or
         $opt_searchTitle    or
         @opt_addPlaylist) {

    print "Your playlist looks empty. Let's add some music!\n";
    sub listlen_help {
      print << 'FOO';
      OPTIONS:
        rand <integer>        randomize a new playlist with <integer> tracks
        add <string>          add <string> playlist(s)
        sdb <pattern>         search the database for <pattern>. 
        sar <pattern>         search for artists matching <pattern>
        sal <pattern>         search for albums matching <pattern>
        set <pattern>         search for titles matching <pattern>

FOO
    }
    &listlen_help;

    print 'pimpd> ';
    while(my $action = <STDIN>) {
      if($action =~ /^sdb\s+(.+)/) {
        my $search = $1;
        &searchDatabase($search);
        exit 0;
      }
      elsif($action =~  /^rand\s+(.+)/) {
        my $no = $1;
        &randomize($no);
        exit 0;
      }
      elsif($action =~ /add\s+(.+)/) {
        my $list = $1;
        my @lists = split(/\s/, $list);
        &addPlaylist(@lists);
        exit 0;
      }
      elsif($action =~ /set\s+(.+)/) {
        my $search = $1;
        &searchTitle($search);
        $mpd->play;
        exit 0;
      }
      elsif($action =~ /sar\s+(.+)/) {
        my $search = $1;
        &searchArtist($search);
        $mpd->play;
        exit 0;
      }
      elsif($action =~ /sal\s+(.+)/) {
        my $search = $1;
        &searchAlbum($search);
        $mpd->play;
        exit 0;
      }
      else {
        &listlen_help;
        print 'pimpd> ';
      }
    }
  }
}
print &currentlyPlaying, "\n"          if $opt_currentlyPlaying;
&information                           if $opt_information;
&showPlaylist                          if $opt_showPlaylist;
&favlist                               if $opt_favlist;
&listAlbums                            if $opt_listAlbums;
&playSongFromList                      if $opt_playSongFromList;
&monitoring                            if $opt_monitoring;
&monitoring                            if $opt_monitor_d;
&randomize($opt_randomize)             if $opt_randomize;
&addPlaylist(@opt_addPlaylist)         if @opt_addPlaylist;
&queue(@opt_queue)                     if @opt_queue;
&ctrl                                  if $opt_ctrl;
&listExternal(@opt_listExternal)       if @opt_listExternal;
&searchPlaylist($opt_searchPlaylist)   if $opt_searchPlaylist;
&searchDatabase($opt_searchDatabase)   if $opt_searchDatabase;
&searchAlbum($opt_searchAlbum)         if $opt_searchAlbum;
&searchArtist($opt_searchArtist)       if $opt_searchArtist;
&searchTitle($opt_searchTitle)         if $opt_searchTitle;


sub information {
  my %current = ('artist'     =>  $mpd->current->artist,
                 'album'      =>  $mpd->current->album,
                 'title'      =>  $mpd->current->title,
                 'genre'      =>  $mpd->current->genre,
                 'file'       =>  $mpd->current->file,
                 'date'       =>  $mpd->current->date,
                 'time'       =>  $mpd->status->time->sofar.'/'.
                                  $mpd->status->time->total,
                 'bitrate'    =>  $mpd->status->bitrate,
                 'audio'      =>  $mpd->status->audio,
                 );
  my %status  = ('repeat'     =>  $mpd->status->repeat,
                 'shuffle'    =>  $mpd->status->random,
                 'xfade'      =>  $mpd->status->xfade,
                 'volume'     =>  $mpd->status->volume,
                 'state'      =>  $mpd->status->state,
                 'list'       =>  $mpd->status->playlist,
                 );
  my %stats   = ('song'       =>  $mpd->status->song,
                 'length'     =>  $mpd->status->playlistlength,
                 'songs'      =>  $mpd->stats->songs,
                 'albums'     =>  $mpd->stats->albums,
                 'artists'    =>  $mpd->stats->artists,
                 );

  if($current{'bitrate'} < 192) {
    $current{'bitrate'} = $clr[0].$current{'bitrate'}.$clr[9];
  }
  foreach my $tag(keys(%current)) {
    if(!$current{$tag}) {
      $current{$tag} = $clr[0].'undef'.$clr[9];
    }
  }
  if($status{state} eq 'play') {
    $status{state} = 'playing';
  }
  if($status{state} eq 'stop') {
    $status{state} = 'stopped';
  }
  if($status{state} eq 'pause') {
    $status{state} = 'paused';
  }
  printf("$clr[4]S%10s$clr[9] %.66s \n", 'Artist:', $current{artist});
  printf("$clr[4]O%10s$clr[9] %.66s \n", 'Album:' , $current{album});
  printf("$clr[4]N%10s$clr[9] %.66s \n", 'Song:'  , $current{title});
  printf("$clr[4]G%10s$clr[9] %.66s \n", 'Genre:' , $current{genre});
  printf("$clr[4] %10s$clr[9] %.66s \n", 'File:'  , $current{file});
  printf("$clr[4]I%10s$clr[9] %.66s \n", 'Year:'  , $current{date});    
  printf("$clr[4]N%10s$clr[9] %.66s \n", 'Time:'  , $current{time});
  printf("$clr[4]F%10s$clr[9] %.66s \n", 'Rate:'  , $current{bitrate});
  printf("$clr[4]O%10s$clr[9] %.66s \n", 'Audio:' , $current{audio});
  print '-' x 25, "\n";
  printf("$clr[3]S%10s$clr[9] %.66s \n", 'Repeat:', $status{repeat});
  printf("$clr[3]T%10s$clr[9] %.66s \n", 'Shuffle:',$status{shuffle}); 
  printf("$clr[3]A%10s$clr[9] %.66s \n", 'Xfade:', $status{xfade});
  printf("$clr[3]T%10s$clr[9] %.66s \n", 'Volume:', $status{volume});
  printf("$clr[3]U%10s$clr[9] %.66s \n", 'State:', $status{state});
  printf("$clr[3]S%10s$clr[9] %.66s \n", 'List V:', $status{list});
  print '-' x 25, "\n";
  printf("$clr[2]S%10s$clr[9] %.66s \n", 'Song:', $stats{song});
  printf("$clr[2]T%10s$clr[9] %.66s \n", 'List:', $stats{length} . ' songs');
  printf("$clr[2]A%10s$clr[9] %.66s \n", 'Songs:', $stats{songs});
  printf("$clr[2]T%10s$clr[9] %.66s \n", 'Albums:', $stats{albums});
  printf("$clr[2]S%10s$clr[9] %.66s \n", 'Artists:', $stats{artists});

exit 0;
}

sub randomize {
  my $count = shift // 100;
  my @songs = $mpd->collection->all_pathes;
  @songs    = shuffle(@songs);
  $mpd->playlist->clear;
  $mpd->playlist->add(@songs[0 .. $count-1]);
  $mpd->random(1);
  $mpd->repeat(1);
  $mpd->play;
  my $message = "Added $count random songs:\n\n";
  &showPlaylist($message);
  exit 0;
} 
 
sub showPlaylist {
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
# titlecase
    $title  =~ s/(\w+)/\u\L$1/g;
    $album  =~ s/(\w+)/\u\L$1/g;
    $artist =~ s/(\w+)/\u\L$1/g;
    ++$i;
    
# 80 columns
    printf"%03i $clr[4]%25.25s $clr[9]| $clr[6]%-47.47s $clr[9] \n",
          $i,$artist, $title;
  }
  print "\n", &currentlyPlaying, "\n";
  exit 0;
}

sub addPlaylist {
  if(@_) {
    my @playlists = @_;
    $mpd->playlist->clear;
    foreach my $playlist(@playlists) {
      $mpd->playlist->load($playlist);
    }
    print ">> Adding...\n";
    print "> ", "$_\n" for(@playlists);
    $mpd->play;
    exit 0;
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

sub listExternal {
  my @playlists = @_;

  foreach my $playlist(@playlists) {
    my $fullpath = "$playlist_dir/$playlist\.m3u";
    open(PLAYLIST, $fullpath) || die "Unable to open $fullpath: $!\n";
    while(<PLAYLIST>) {
      my $list = $_;
      print "$clr[4]$playlist$clr[9]: $list";
    }
    close(PLAYLIST);
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

sub cptoPort {
  use File::Copy;
  my $dir  = $ARGV[0] // $portable;
  my $file = $mpd->current->file;
  if(defined($remote_host)) {
    return scp1($remote_host, $basedir.$file, $dir);
  }
  chomp($file);
  copy("$basedir/$file", $dir) or die "Failure: $! \n";

  exit 0;
}

sub favlist {
  my $playlist = $ARGV[0] // lc($mpd->current->genre) // $fallback_playlist;
  my $filepath = $mpd->current->file;
  my $fullpath = "$playlist_dir/$playlist";
  open PLAYLIST, ">>$fullpath\.m3u" or die 
                                    "Could not open playlist: $!\n";
  print PLAYLIST $filepath, "\n";
  close PLAYLIST;
  my $history_path = "$playlist_dir/$history_playlist";
  open HISTORY, ">>$history_path\.m3u" or die 
                                       "Could not open history: $!\n";
  print HISTORY $filepath, "\n";
  close HISTORY;
  print $clr[1].$filepath,$clr[9].' >> ',$clr[3]."$fullpath\.m3u",$clr[0], "\n";

  exit 0;
}

sub listAlbums {
  my $artist = $ARGV[0] // $mpd->current->artist;
  my @albums = sort($mpd->collection->albums_by_artist($artist));
  print "$clr[1]$artist$clr[9] is featured on:\n\n";
  foreach my $album(@albums) {
    print $album, "\n";
  }
  exit 0;
}

sub playSongFromList {
  my $choice = $ARGV[0];
  $mpd->play($choice);
  print &currentlyPlaying;

  exit 0;
}

sub lyrics {
  use LWP::Simple;
  use HTML::TokeParser::Simple;
  use Text::Autoformat qw(autoformat);
  my $artist = $mpd->current->artist;
  my $song   = $mpd->current->title;
  my $url = "http://lyricsplugin.com/winamp03/plugin/?artist=".
            "$artist&title=$song";
  my $lyrics = get($url);
  my $p      = HTML::TokeParser::Simple->new(string=>$lyrics);

  my @lyrics;
  while(my $token = $p->get_token) {
    next unless($token->is_text);
    push(@lyrics, $token->as_is);
  }
# 26 elements if no text
  if(scalar(@lyrics)<27) {
    print "Sorry, no lyrics found.\n";
    exit 0;
  }
  
  # autoformat doesnt seem to handle arrays :/
  my @foobar = (@lyrics[12..@lyrics-13]);
  my $foo = join("", @foobar);

  printf("%2s by %s:\n", $song, $artist);
  print autoformat $foo, {left     => 0,
                          right    => 80,
                          all      => 1,
                          justify  => 'centre',
                          fill     => 0,
                          tabspace => 2,
                          case     => 'sentence'};
   exit 0;
} 

sub monitoring {
  my $np = "";
  use Proc::Daemon;
  print "Daemonizing...\n" if $opt_monitor_d;
  Proc::Daemon::Init if $opt_monitor_d;
  while(1) {
    my $current = $mpd->current // undef;
    my $output;
    if($opt_monitor_d) {
      my $artist = $mpd->current->artist // 'undef';
      my $album  = $mpd->current->album  // 'undef';
      my $title  = $mpd->current->title  // 'undef';
      my $genre  = $mpd->current->genre  // 'undef';
      $output = sprintf("%s (%s) %s | %s", $artist, $album, $title, $genre);
    }
    
    if("$np" ne "$current") {
      $np = $current;
      if($opt_monitor_d) {
        system("$daemon_cmd \"$output\"");
      }
      else {
        my @date = localtime(time);
        my @rclr = shuffle(@clr);
        my $file = $mpd->current->file;
        printf("%02s:%02s:%02s | $rclr[0]%.68s$clr[9]\n",
               $date[2], $date[1], $date[0], $file);
           }
         }
         sleep 2;
       }
     }
sub queue {
  my @to_play = @_;
  if(@to_play < 1) {
    print STDERR "The queue function requires at least one song \n";
    exit 1;
  }
  my @tracksinlist = $mpd->playlist->as_items;

  my $argc         = 0;

  print ">> Starting queue...\n";
  while(scalar(@to_play) > $argc) {
    $mpd->play($to_play[$argc]);
    my $time = $mpd->current->time;
    ++$argc;
    
    my $nextpos = $to_play[$argc];
    print &currentlyPlaying, "\n";
    printf("$clr[13]>>> %s - %s - %s $clr[9]\n",
                                 $tracksinlist[$nextpos]->artist,
                                 $tracksinlist[$nextpos]->album,
                                 $tracksinlist[$nextpos]->title)
    unless scalar(@to_play) == $argc;
    print '-' x 40, "\n" unless scalar(@to_play) == $argc;

    sleep $time;
  }
  print ">> Queue finished.\n";
}

sub ctrl {
  my $option = shift;
  print << 'CMD';
This is the pimpd shell for simple interacting with MPD.

 Available commands are:

 n    next track
 p    previous track
 t    toggle pause/play
 s    shuffle the playlist
np    print currently playing song
ra    toggle random on/off
re    toggle repeat on/off
cl    clear the playlist
cr    remove all tracks in playlist except for the current one

  :q|exit exit

CMD

  my $ctrlOptions = {
    'n'  =>  sub {$mpd->next; print &currentlyPlaying, "\n"},
    'p'  =>  sub {$mpd->prev; print &currentlyPlaying, "\n"},
    't'  =>  sub {$mpd->pause; print $mpd->status->state, "\n"},
    's'  =>  sub {$mpd->playlist->shuffle; print $mpd->status->playlist, "\n"},
    'np' =>  sub {print &currentlyPlaying, "\n"},
    'ra' =>  sub {$mpd->random; print $mpd->status->random, "\n"},
    're' =>  sub {$mpd->repeat; print $mpd->status->repeat, "\n"},
    'cl' =>  sub {$mpd->playlist->clear},
    'cr' =>  sub {$mpd->playlist->crop},
    ':q' =>  sub {exit 0},
  };

  print '-' x 40, "\n";
  while(1) {
    print "pimpd> ";
    my $choice = <STDIN>;
    chomp($choice);
    defined $ctrlOptions->{$choice} && $ctrlOptions->{$choice}->();
  }
}
sub searchPlaylist {
  my $search   = shift;
  my @playlist = $mpd->playlist->as_items;
  my @found;
  
  foreach my $song(@playlist) {
    if($song =~ /$search/i) {
      print '> ', $song->title, "\n";
      push(@found, $song->pos);
    }
  }
  &queue(@found);
}

sub searchDatabase {
  my $search = shift; 
  my @collection = $mpd->collection->all_pathes;

  foreach my $song(@collection) {
    if($song =~ /$search/i) {
      printf("> %.77s\n", $song); 
      $mpd->playlist->add($song);
    }
  }
  $mpd->play;
  exit 0;
}

sub searchAlbum {
  my $search = shift;
  my @tracks = $mpd->collection->songs_from_album_partial($search); 
  if(!@tracks) {
    print ">> $clr[2]$search$clr[9]: no tracks found\n";
    exit 1;
  }
  my @files;
  foreach my $track(@tracks) {
    push(@files, $track->file);
  }
  &pipeAdd(@files);
  print ">> ", $clr[1], scalar(@files), $clr[9],
        " albums found matching $clr[3]$search $clr[9]\n";
}

sub searchArtist {
  my $search = shift;
  my @artists = $mpd->collection->songs_by_artist_partial($search);
  if(!@artists) {
    print ">> $clr[2]$search$clr[9]: nothing found\n";
    exit 1;
  }
  my @files;
  foreach my $artist(@artists) {
    push(@files, $artist->file);
  }
  &pipeAdd(@files);
  print ">> ", $clr[1], scalar(@artists)-1, $clr[9], 
        " tracks found by artist(s) matching $clr[3]$search $clr[9]\n";
}

sub searchTitle  {
  my $search = shift;
  my @songs = $mpd->collection->songs_with_title_partial($search);
  if(!@songs) {
    print ">> $clr[2]$search$clr[9]: nothing found\n";
    exit 1;
  }
  my @files;
  foreach my $song(@songs) {
    push(@files, $song->file);
  }
  &pipeAdd(@files);
  print ">> ", $clr[1], scalar(@songs)-1, $clr[9],
        " titles found matching $clr[3]$search $clr[9]\n";
}

sub pipeAdd {
  my @files = (@_);
  foreach my $file(@files) {
    print $file, "\n";
    $mpd->playlist->add($file);
  }
} 
  
sub currentlyPlaying {
  my $artist  = $clr[3].$mpd->current->artist.$clr[9] // 'undef';
  my $song    = $clr[4].$mpd->current->title.$clr[9]  // 'undef';
  my $bitrate = $mpd->status->bitrate                 // 'undef';
  my $genre   = $clr[1].$mpd->current->genre.$clr[9]  // 'undef';

  my $current = "$clr[1] >>$clr[9] $artist - $song ($bitrate kbps) [$genre]";

  return $current;
}

sub help {
  print << "HELP";
  $APPLICATION_NAME $APPLICATION_VERSION
  Copyright (C) 2009-2010 Magnus Woldrich. Licensed under the GNU GPL version 2.
  Usage: $0 [OPTIONS] (ARGUMENT)

  OPTIONS:
      -i, --info          print current information
     -np, --current       print current information in one line
      -r, --randomize     randomize a new playlist with <integer> tracks
      -c, --copy          copy the current track to location <string> 
      -f, --favorite      favorize the current track. If no name for the
                          playlist is given, the 'genre' id3-tag is used
      -l, --listalbums    list all albums by <string> or current artist
      -s, --show          show current playlist
      -p, --play          play the number <integer> track in playlist
      -a, --add           add playlist <string> and play it
      -m, --monitor       monitor MPD for song changes, output on STDOUT
     -ly, --lyrics        show lyrics for the current song
      -q, --queue         queue <integer> tracks in playlist
      -e, --external      list all tracks in external playlist <string>
     -ct, --ctrl          spawn the interactive pimpd shell 
    -spl, --search-pl     search the active playlist for <pattern>
    -sdb, --search-db     search the database for <pattern> and add the 
                          results to active playlist
    -sar, --search-artist search for artist name containing <string>
    -sal, --search-album  search for album name containing <string>
    -set, --search-title  search for song title containing <string>
     -no, --nocolor       dont use colorized output

      -h, --help          show this help

  PATTERN is Perl RE: '(foo|bar)', '(foo)?bar', 'foobarb.*', 'foo(\d+)'
HELP
exit 0;
}
