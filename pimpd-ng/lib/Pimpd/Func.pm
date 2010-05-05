package Pimpd::Func;
require Exporter;
@ISA = qw(Exporter);
@EXPORT_OK = qw(findartist);


sub findartist {
  my $artist = shift;
  my @artists = $mpd->collection->songs_by_artist_partial($search);
  return undef if !@artists;
  my @files;
  foreach my $artist(@artists) {
    push(@files, $artist->file;
  }
  return @files;
}
