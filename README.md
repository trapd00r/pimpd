# NAME

  pimpd - Perl Interface for the Music Player Daemon

# SYNOPSIS

  pimpd [OPTIONS...] (ARG)

# DESCRIPTION

  ![pimpd screenshot](http://github.com/trapd00r/pimpd/raw/master/docs/screenshot.png "pimpd screenshot")

pimpd is an MPD client written in Perl that aims to implement what the
excellent mpc client is lacking (for good reasons), as well as all the
regular functionality one would expect.

- Regular expression based queries

  You can search the database and playlist using regular expressions. There are
  several other (faster) ways to search as well - by artist, album or title.

- Randomizing

  The 'I am lucky button' - add n randomly picked tracks to the current
  playlist.

- Transfering of music

  There are several ways of transfering music.

  This is especially useful if the MPD server is running elsewhere and you want
  to listen to the music locally, or if you want to transfer some music to your
  portable music player.

    -cp  simply copies the currently playing track to the specifed location.

    -cpa copies the full album where the currently playing track is featured.

    -cpl copies all tracks in the specified playlist to the specified location.

- Interactive shell

  From the interactive shell one can access almost all functionality that's
  available through regular option flags.

- Monitor song changes

  There are two ways to monitor song changes:

    -m  simply print song changes to stdout.

    -md monitor in daemon mode.

  This is useful for things like OSD notifications, integration in dzen2 / conky
  and so on. Most window managers uses their own sort of notification
  functionality which can also be used.

- Now playing

  There are two options that will yeild some info on the current track:

    -i   print all information available.

    -np  print information on the currently playing track only, on a single line.

- Colors

  pimpd does support colorschemes, which are defined and loaded from the
  configuration file. 256 colors is supported, as well as no colors at all.



  All of this works on local MPD servers as well as remote ones.

# OPTIONS

    -i,     --info          print all information available
    -np,    --current       print now playing information on single line
    -r,     --random        randomize a new playlist with n tracks
    -cp,    --copy          copy the current track to specified location (C)
    -cpa,   --cp-album      copy the whole album the current track is featured on
                            to specified location
    -cpl,   --cp-list       copy the content of specified playlist to specifed
                            location
    -f,     --fav           favorize the current track. If no name for the playlist
                            is specified, the GENRE id3-tag is used
    -l,     --listalbums    list all albums by artist
    -lsp,   --list-pl       list all available playlists
    -p,     --playlist      show the current playlist
    -t,     --track         play track number n from playlist
    -a,     --add           add playlist and play it
    -m,     --monitor       monitor MPD for song changes (output on STDOUT)
    -md,    --monitor-d     monitor MPD for song changes in daemon mode. Where the
                            output should go is specified in the configuration file.
    -k,     --kill          kill pimpd when running in daemon mode
    -q,     --queue         queue specified tracks
    -e,     --external      list all tracks in external playlist
    -sh,    --shell         spawn the interactive pimpd shell
    -spl,   --search-pl     search the current playlist for pattern and queue the
                            results
    -sdb,   --search-db     search the database for pattern and add the results to
                            the current playlist
    -sar,   --search-artist search the database for artist and add the results to
                            the current playlist
    -sal,   --search-album  search the database for album and add the result to
                            the current playlist
    -set,   --search-title  search the database for title and add the results to
                            the current playlist
    -no,    --no-color      turn colors off (C)
            --mpd-kill      shut down the MPD server
            --host          remote MPD host (C)
            --port          remote MPD port (C)
            --pass          remote MPD password (C)
            --ssh-host      remote SSH server host (used for -cp) (C)
            --ssh-port      remote SSH server port (used for -cp) (C)
            --ssh-user      remote SSH server user (used for -cp) (C)

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
