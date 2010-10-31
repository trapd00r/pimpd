# NAME

  pimpd - Perl Interface for the Music Player Daemon

# SYNOPSIS

  pimpd [OPTIONS...] (ARG)

# DESCRIPTION

  ![pimpd screenshot](http://github.com/trapd00r/pimpd/raw/master/docs/screenshot.png "pimpd screenshot")

pimpd is an MPD client written in Perl that aims to implement what the
excellent mpc client is lacking (for good reasons), as well as all the
regular functionality one would expect.

### Local playback

  If defined in the configuration file, an external player can be used for
  playback of music running on another box (the MPD server). This is fully
  transparent; when MPD is stopped, so is the external player.

  When the --play flag is given, pimpd will connect to MPD and start playback
  if neccessary, and at the same time connect to the stream with the specified
  external player.

  Issues with unreliable network connections/slow disks causing the external
  player to exit is eliminated, as well as scenarios where the MPD playlist
  might be temporary empty (no playback - external player exits).

### Regular expression based queries

  You can search the database and playlist using regular expressions. There are
  several other (faster) ways to search as well - by artist, album or title.

  Additionally, it's possible to search through all favlists at the same time,
  adding the matches to the current playlist. Since pimpd internally keeps an
  csv-style database up to date with the favorized tracks, it's enough to search
  for artist, album, title, genre and/or file, in any combination.

### Randomizing

  -r will create a new playlist with <num> randomly selected tracks from the
     database added.

  -rt will play a random track from the current playlist.

### Favorites

  Favorites are handled in several ways. When the -f flag is used, pimpd will
  check for the genre tag of the song and, if existing, save it in the playlist
  directory with a year-month_genre-notation.
  If there's no genre tag, the $fallback_playlist, specified in the
  configuration file, is used.

  pimpd will also keep a CSV-style database updated with more additional data on
  the song. This have several purposes:

  * other applications might expect regular m3u-style playlists with only a
    defined "file"-field,

  * the database holds additional information on the favorites, which allows for
    more powerful search capabilities, and

  * we can generate nifty stats for loved songs

### Transfering of music

  There are several ways of transfering music.

  This is especially useful if the MPD server is running elsewhere and you want
  to listen to the music locally, or if you want to transfer some music to your
  portable music player.

  The $ssh_host, $ssh_port and $ssh_user variables in the configuration file
  must be defined in the configuration file, and you must be using SSH keys for
  this to work over networks.

  -cp  simply copies the currently playing track to the specifed location.

  -cpa copies the full album where the currently playing track is featured.

  -cpl copies all tracks in the specified playlist to the specified location.

### Interactive shell

  From the interactive shell one can access almost all functionality that's
  available through regular option flags.

### Monitor song changes

  There are two ways to monitor song changes:

  -m  simply print song changes to stdout.

  -md monitor in daemon mode. This is useful for things like OSD notifications,
      integration in dzen2 and so on. Most window managers uses their own sort
      of notification functionality which can also be used.

### Now playing

  There are three options that will yeild some info on the current track:

  -i     print all information available.

  -np    print information on the currently playing track only, on a single line.

  -nprt  print information on the currently playing track in realtime mode.

### Colors

  pimpd does support colorschemes, which are defined and loaded from the
  configuration file. 256 colors is supported, as well as no colors at all.

  All of this works on local MPD servers as well as remote ones.

# OPTIONS

      -i,     --info          show all info for the currently playing song
      -np,    --current       print basic song info on a single line
              --np-rt         print updating song info on a single line
      -r,     --random        randomize a new playlist with <num> tracks
      -rt,    --random-track  play a random track from the playlist
      -cp,    --copy          copy the current track to specified location
      -cpa,   --cp-album      copy the current album to specified location
      -cpl,   --cp-list       copy playlist <str> to specified location
      -f,     --fav           add the current track to the favorites
      -fs,    --favstats      generate statistics based on previous favorizations
      -l,     --listalbums    list all albums featuring artist
      -lsa,   --listsongs     list all songs on the current album
      -lsp,   --list-pl       list all available playlists
      -pls    --playlist      show the current playlist
      -t,     --track         play track <num> from playlist
      -a,     --add           add playlist <str>. If <str> eq "all", add all
      -aa,    --add-album     add the current album to the playlist
      -m,     --monitor       monitor MPD for song changes (output on STDOUT)
      -md,    --monitor-d     monitor MPD for song changes in daemon mode
      -k,     --kill          kill pimpd when running in daemon mode
      -q,     --queue         queue <num> tracks
      -e,     --external      list all tracks in external playlist
      -sh,    --shell         spawn the interactive pimpd shell
      -spl,   --search-pl     search the playlist for [<pattern>]
      -sdb,   --search-db     search the database for [<pattern>]
      -sar,   --search-artist search the database for [<artist>]
      -sal,   --search-album  search the database for [<album>]
      -set,   --search-title  search the database for [<title>]
      -sap,   --favsearch     search the favlists for artist, album, title, file
      -c,     --clear         clear the playlist before performing any action that
                              generates a new playlist
              --play          start remote/local playback
              --stop          stop remote/local playback
      -no,    --no-color      turn colors off
              --mpd-kill      shut down the MPD server
              --host          remote MPD host
              --port          remote MPD port
              --pass          remote MPD password
              --ssh-host      remote SSH server host
              --ssh-port      remote SSH server port
              --ssh-user      remote SSH server user

      -h,     --help          show the help and exit
              --man           show the manpage and exit

# ENVIRONMENT

The configuration file should be placed in $XDG_CONFIG_HOME/pimpd/pimpd.conf OR
/etc/pimpd.conf

# AUTHOR

Written by Magnus Woldrich

# REPORTING BUGS

Report bugs and feature requests at the issue tracker
<http://github.com/trapd00r/pimpd/issues>

Girls can contact me at <trapd00r@trapd00r.se>

# COPYRIGHT

Copyright (C) 2009, 2010 Magnus Woldrich

# SEE ALSO

__rmcd__  <http://github.com/trapd00r/rmcd>
