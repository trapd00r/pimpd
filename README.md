# NAME

  pimpd - Perl Interface for the Music Player Daemon

# SYNOPSIS

  pimpd [OPTIONS...] (ARG)

# DESCRIPTION

  ![pimpd screenshot](http://github.com/trapd00r/pimpd/raw/master/doc/screenshot.png "pimpd screenshot")

  pimpd is an MPD client written in Perl that implements regular expression
  based database/playlist queries, randomizing of playlists, queue
  functionality, interactive shell, monitoring (to STDOUT and daemonized),
  ability to copy the currently playing song to your portable player, favorizing
  of specific tracks.
  
  Loads of information can be spammed, support for colorschemes (and 256
  colors).
  
  See the  OPTIONS for a full specification.

  All of this works on local MPD servers as well as remote ones.

# OPTIONS

    -i,     --info          print all information available
    -np,    --current       print now playing information on single line
     -r,     --random        randomize a new playlist with n tracks
    -cp,    --copy          copy the current track to specified location (C)
    -f,     --fav           favorize the current track. If no name for the playlist
                            is specified, the GENRE id3-tag is used
    -l,     --listalbums    list all albums by artist
    -p,     --playlist      show the current playlist
    -t,     --track         play track number n from playlist
    -a,     --add           add playlist and play it
    -m,     --monitor       monitor MPD for song changes (output on STDOUT)
    -md,    --monitor-d     monitor MPD for song changes in daemon mode. Where the
                            output should go is specified in the configuration file.
    -q,     --queue         queue specified tracks
    -e,     --external      list all tracks in external playlist
            --ctrl          spawn the interactive pimpd shell
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
            --host          remote MPD host (C)
            --port          remote MPD port (C)
            --pass          remote MPD password (C)
            --ssh-host      remote SSH server host (used for -cp) (C)
            --ssh-port      remote SSH server port (used for -cp) (C)
  
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

Report your love and send virtual hugs to <trapd00r@trapd00r.se>
If you need to send more then virtual hugs - contact me by the mail first.

# COPYRIGHT

Copyright (C) 2009, 2010 Magnus Woldrich

# SEE ALSO

__rmcd__  <http://github.com/trapd00r/rmcd>
