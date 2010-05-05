package Pimpd::Func;
require Exporter;
@ISA = qw(Exporter);
@EXPORT_OK = qw(playing getlist play add search status load);
use Data::Dumper;
use Audio::MPD;
my $mpd = Audio::MPD->new;

sub search {
  my $tag   = shift; # artist,album,title
  my $query = shift; # laleh, simon\ and\ i
  my $mpdFunc;
  my $searches = {
    artist  => sub {$mpdFunc = 'songs_by_artist_partial';},
    album   => sub {$mpdFunc = 'songs_from_album_partial';},
    title   => sub {$mpdFunc = 'songs_with_title_partial';},
  };
  defined $searches->{$tag} && $searches->{$tag}->();
  return ($mpd->collection->$mpdFunc($query));
}

sub playing {
  my $playing = sprintf("%.24s - %.24s (%.24s)",
    $mpd->current->artist, $mpd->current->title, $mpd->current->album);
  return $playing;
}

sub getlist {
  return ($mpd->playlist->as_items);
}

sub play {
  my $no = shift;
  $mpd->play && exit 0 unless $no;
  $mpd->play($no);
}
sub add {
  my @files = @_;
  chomp(@files);
  $mpd->playlist->add(@files);
}

sub load {
  my $list = shift;
  $mpd->playlist->load($list);
}

sub status {
  my $np = playing();
  my $strstate;
  my $state = {
    pause => sub {$strstate = 'paused';},
    play  => sub {$strstate = 'playing';},
    stop  => sub {$strstate = 'stopped';},
    ''    => sub {$strstate = 'stopped';},
  };
  defined $state->{$mpd->status->state} && $state->{$mpd->status->state}->();
  my $songpos = sprintf("#%d/%d",
    $mpd->status->song, $mpd->status->playlistlength);
  my $songelap = sprintf("%s/%s (%s%)",
    $mpd->status->time->sofar, $mpd->status->time->total,
    $mpd->status->time->percent);
  my $volume = $mpd->status->volume;
  my $repeat = $mpd->status->repeat;
  my $random = $mpd->status->random;
  my $xfade  = $mpd->status->xfade;
  my $output = sprintf(
    "%s\n[%s] %s  %s\nvolume: %s  repeat: %s  random: %s  crossfade: %s\n",
    playing(), $strstate, $songpos, $songelap, onoff($volume), onoff($repeat),
    onoff($random), onoff($xfade));
  return $output;
}

sub onoff {
  my $status = shift;
  return 'on'  if $status == 1;
  return 'off' if $status == 0;
  return 'n/a' if $status < 0;
}
