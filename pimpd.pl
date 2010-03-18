#!/usr/bin/perl 
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
our ($basedir, $playlist_dir, $fallback_playlist, $portable,
     $remote_host, $remote_pass, $remote_user);

my $APPLICATION_NAME    = 'pimpd';
my $APPLICATION_VERSION = '1.1.0';

my $mpd;
if(defined($remote_host)) {
  $mpd = Audio::MPD->new(host     =>  $remote_host,
                         password =>  $remote_pass,
                         );
}
else {
  $mpd = Audio::MPD->new;
}

our (@opt_queue, $opt_ctrl, @opt_list_external_list,
     $search_pl_pattern, $search_db_pattern, $opt_information, #FIXME
     $opt_randomize, @opt_add_playlist);

my @clr = ("\033[31m", "\033[31;1m", "\033[32m", "\033[32;1m", "\033[33m",
           "\033[34m", "\033[34;1m", "\033[36m", "\033[36;1m", "\033[0m");


if(!@ARGV) {
  &help;
}

# :{,} == zero or more
GetOptions('information'     =>  \$opt_information,
           'randomize:i'     =>  \$opt_randomize,
           'copy'            =>  \&cp2port,
           'favorite'        =>  \&favlist,
           'listalbums'      =>  \&listalbums,
           'show'            =>  \&show_playlist,
           'play'            =>  \&play_song_from_pl,
           'add=s{1,}'       =>  \@opt_add_playlist,
           'monitor'         =>  \&monitoring,
           'queue=i{1,}'     =>  \@opt_queue,
           'lyrics'          =>  \&lyrics,
           'ctrl'            =>  \$opt_ctrl,
           'external=s{1,}'  =>  \@opt_list_external_list,                          
           'spl|search-pl=s' =>  \$search_pl_pattern,
           'sdb|search-db=s' =>  \$search_db_pattern,

           'help'            =>  \&help,
           'bighelp'         =>  \&bighelp,
           );
if($mpd->status->playlistlength < 1) {
  print "Your playlist seems empty. Let us add some music!\n";
  sub listlen_help {
    print << 'FOO';
    OPTIONS:
      randomize <number>    randomize a new playlist with <number> tracks
      add <string>          add <string> playlist(s)
      search <pattern>      search the database for <pattern>. 
                            Note that you shouldn't escape the pattern like
                            in the shell; f(oo)?b.r will do just fine.
FOO
  }
  &listlen_help;

  print 'pimpd> ';
  while(<STDIN>) {
    my $action = $_;
  
    if($action =~ /^search\s+(.+)/) {
      my $search = $1;
      &search_database($search);
    }
    elsif($action =~  /^randomize\s+(.+)/) {
      my $no = $1;
      &randomize($no);
    }
    elsif($action =~ /add\s+(.+)/) {
      my $list = $1;
      my @lists = split(/\s/, $list);
      &add_playlist(@lists);
    }

    else {
      &listlen_help;
      print 'pimpd> ';
    }
  }
}

my $notag         = $clr[0].'undef'.$clr[9]; 
my $curr_artist   = $mpd->current->artist  // $notag;
my $curr_album    = $mpd->current->album   // $notag;
my $curr_title    = $mpd->current->title   // $notag;
my $curr_genre    = $mpd->current->genre   // $notag;
my $curr_file     = $mpd->current->file;
my $curr_date     = $mpd->current->date    // $notag;
my $curr_rate     = $mpd->status->bitrate  // $notag;
my $curr_time     = $mpd->status->time->sofar.'/'.$mpd->status->time->total;
my $curr_audio    = $mpd->status->audio;
my $stat_artists  = $mpd->stats->artists;
my $stat_albums   = $mpd->stats->albums;
my $stat_songs    = $mpd->stats->songs;
my $status_rep    = $mpd->status->repeat;
my $status_rnd    = $mpd->status->random;
my $status_xfade  = $mpd->status->xfade;
my $status_volume = $mpd->status->volume.'%';
my $state         = $mpd->status->state;
my $status_pl_ver = $mpd->status->playlist;
my $status_pl_len = $mpd->status->playlistlength.' songs';
my $song_no       = $mpd->status->song;

if($opt_information) {
  &information;
}
if($opt_randomize) {
  &randomize($opt_randomize);
}
if(@opt_add_playlist) {
  &add_playlist(@opt_add_playlist);
}

if(@opt_queue) {
  &queue(@opt_queue);
}
if($opt_ctrl) {
  &ctrl;
}
if(@opt_list_external_list) {
  &list_external_list(@opt_list_external_list);
}
if($search_pl_pattern) {
  &search_active_pl($search_pl_pattern);
}
if($search_db_pattern) {
  &search_database($search_db_pattern);
}

 sub information {
  if($curr_rate < 192) {
    $curr_rate = $clr[0].$curr_rate.$clr[9];
  }
  
  # We're truncating lines that'll span over 80 columns. 80-14=66.
  printf("$clr[0]S$clr[9] %10s %.66s \n", 'Artist:', $curr_artist); 
  printf("$clr[0]O$clr[9] %10s %.66s \n", 'Album:', $curr_album);
  printf("$clr[0]N$clr[9] %10s %.66s \n", 'Song:', $curr_title);
  printf("$clr[0]G$clr[9] %10s %.66s \n", 'Genre:', $curr_genre);
  printf("$clr[0] $clr[9] %10s %.66s \n", 'File:', $curr_file);
  printf("$clr[0]I$clr[9] %10s %.66s \n", 'Year:', $curr_date);
  printf("$clr[0]N$clr[9] %10s %.66s \n", 'Time:', $curr_time);
  printf("$clr[0]F$clr[9] %10s %.66s \n", 'Bitrate:', $curr_rate);
  printf("$clr[0]O$clr[9] %10s %.66s \n", 'Audio:', $curr_audio);

  print "$clr[9]-" x 30, "\n";
  printf("$clr[4]S$clr[9] %10s %.66s \n", 'Repeat:', $status_rep);
  printf("$clr[4]T$clr[9] %10s %.66s \n", 'Shuffle:', $status_rnd);
  printf("$clr[4]A$clr[9] %10s %.66s \n", 'Xfade:', $status_xfade);
  printf("$clr[4]T$clr[9] %10s %.66s \n", 'Volume:', $status_volume);
  printf("$clr[4]U$clr[9] %10s %.66s \n", 'State:', ucfirst($state));
  printf("$clr[4]S$clr[9] %10s %.66s \n", 'List #:', $status_pl_ver); 

  print "$clr[9]-" x 30, "\n";
  printf("$clr[2]S$clr[9] %10s %.66s \n", 'Song #:', $song_no);
  printf("$clr[2]T$clr[9] %10s %.66s \n", 'PL Length:', $status_pl_len);
  printf("$clr[2]A$clr[9] %10s %.66s \n", 'Songs:', $stat_songs);
  printf("$clr[2]T$clr[9] %10s %.66s \n", 'Albums:', $stat_albums);
  printf("$clr[2]S$clr[9] %10s %.66s \n", 'Artists:', $stat_artists);

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
# titlecase
    $title  =~ s/(\w+)/\u\L$1/g;
    $album  =~ s/(\w+)/\u\L$1/g;
    $artist =~ s/(\w+)/\u\L$1/g;
    ++$i;
    
# 80 columns
    printf"%03i $clr[5]%25.25s $clr[9]| $clr[1]%-47.47s $clr[9] \n",
          $i,$artist, $title;
  }
  print "\n", &currently_playing, "\n";
  exit 0;
}

sub add_playlist {
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

sub list_external_list {
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

sub cp2port {
  my $dir  = $ARGV[0] // $portable;
  my $file = $mpd->current->file;
  if(defined($remote_host)) {
    return scp1($remote_host, $basedir.$file, $dir);
  }
  chomp($file);
  copy("$basedir/$file", $dir) || die "Failure: $! \n";

  exit 0;
}

sub favlist {
  my $playlist = $ARGV[0] // lc($mpd->current->genre) // $fallback_playlist;
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
  print &currently_playing;

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

sub queue {
  my @to_play = @_;
  if(@to_play < 1) {
    print STDERR "The queue function requires at least one song \n";
    exit 1;
  }
  my @tracksinlist = ($mpd->playlist->as_items);

  my $argc         = 0;

  print ">> Starting queue...\n";
  while(scalar(@to_play) > $argc) {
    $mpd->play($to_play[$argc]);
    my $time = $mpd->current->time;
    ++$argc;
    
    my $nextpos = $to_play[$argc];
    print &currently_playing;
    printf(">>> %s - %s - %s\n", $tracksinlist[$nextpos]->artist,
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
 # print 'pimpd>';
 print << 'CMD';
This is the pimpd shell for simple interacting with MPD.

 Available commands are:

 n|next    next track
 p|prev    previous track
 t|toggle  toggles pause/play
re|repeat  toggles repeat on/off
ra|random  toggles random on/off
cr|crop    remove all tracks in playlist except for the current one
 s|shuffle shuffle the current playlist
cl|clear   remove all items from playlist

  :q|exit exit

CMD
print '-' x 40, "\n";
print 'pimpd> ';
  while(<>) {
    my $cmd = $_;

    if($cmd =~ /:q|exit/) {
      print "Quitting...\n";
      exit 0;
    }
    elsif($cmd =~ /(^n$|^next$)/) {
      $mpd->next;
      print '>> ',$mpd->current->artist, ' - ', $mpd->current->album, ' - ',
            $mpd->current->title, "\n", 'pimpd> ';

    }
    elsif($cmd =~ /(^p$|^prev(.+)?$)/) {
      $mpd->prev;
      print '> ',$mpd->current->artist, ' - ', $mpd->current->album, ' - ',
            $mpd->current->title, "\npimpd> ";
    }
    elsif($cmd =~ /(^t$|^toggle$)/) {
      $mpd->pause;
      my $state = $mpd->status->state;
      if($state eq 'play') {
        $state = 'playing';
      }
      if($state eq 'pause') {
        $state = 'paused';
      }
      print "MPD is $state. \n", 'pimpd> ';
    }

    elsif($cmd =~ /(^re$|^repeat$)/) {
      $mpd->repeat;
      my $rep_status = $mpd->status->repeat;
      if($rep_status == 0) {
        $rep_status = 'disabled.';
        }
      else {
        $rep_status = 'enabled.';
      }
      print "Repeat is $rep_status \n" , 'pimpd> ';
    }

    elsif($cmd =~ /(^ra$|^random$)/) {
      $mpd->random;
      my $rand_status = $mpd->status->random;
      if($rand_status == 0) {
        $rand_status = 'disabled.';
      }
      else {
        $rand_status = 'enabled.';
      }
      print "Random is $rand_status \n", 'pimpd> ';
    }
    elsif($cmd =~  /(^cr$|^crop$)/) {
      $mpd->playlist->crop;
      print 'pimpd> ';
    }
    elsif($cmd =~  /(^cl$|^clear$)/) {
      $mpd->playlist->clear;
      print 'pimpd> ';
    }
    elsif($cmd =~ /(^s$|^shuffle$)/) {
      $mpd->playlist->shuffle;
      print 'pimpd> ';
    }
    else {
      print "Option not recognized.\n";
      print 'pimpd> ';
    }
  }
}

sub search_active_pl {
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

sub search_database {
  my $search = shift; 
  print $search x 20;
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

sub currently_playing {
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
  Usage: $0 [OPTIONS] (ARGUMENT)

  OPTIONS:
    -i   | --info           print current information
    -r   | --randomize  (I) randomize a new playlist with <integer> tracks.
                            The default value is 100.
    -c   | --copy [S]       copy the current track to location S
    -f   | --favorite   (S) favorize the current track. If no name for the
                            playlist is given, the 'genre' id3-tag is used
    -l   | --listalbums (S) list all albums by <string> or the current artist
    -s   | --show           show current playlist
    -p   | --play       [I] play number <integer> track in playlist
    -a   | --add        (S) add <string> playlist and play it
    -m   | --monitor        monitor MPD for song changes, output on STDOUT
    -ly  | --lyrics         show lyrics for the current song
    -q   | --queue      [I] queue <integer> tracks in playlist
    -e   | --external   [S] list all tracks in external playlist <string>
    -ct  | --ctrl           spawn the interactive pimpd shell
    -spl | --search-pl  [P] search the active playlist for <pattern> and queue
                            the results. Pattern is Perl RE:
                            '(amiga|atari)?(ninten.{2})'
                            'fooo?b.+'
    -sdb | --search-db  [P] search the database for <pattern> and add the
                            the results to active playlist. See --search-pl.

    -h   | --help           show this help
    -b   | --bighelp        show The Big Help
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
