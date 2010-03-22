Perl Interface for the Music Player Daemon
==========================================

pimpd is an MPD client written in perl that strives to implement the features
mpc is missing. This includes, but is not limited to:

  * Regular expression based database queries
  * Regular expression based searches in active playlist
  * Randomizing of playlist; you could add 100 (carefully!) randomly selected
    tracks to your playlist
  * Fetching of lyrics on demand
  * Queue functionality
  * Interactive shell for basic MPD operations
  * Monitoring of MPD - Whenever a song change takes place, pimpd announces
  * Ability to easily copy current track to specified location; i.e your portable  
    musicplayer of choice or maybe to your to-burn directory
  * Huge load of interesting information regarding what's currently spinning

![screenshot](http://github.com/trapd00r/pimpd/raw/master/pimpd-1.0-screenshot.png)



Please see below for a full list of options.

    Usage: pimpd.pl [OPTIONS] (ARGUMENT)

    OPTIONS:
        -i, --info        print current information
        -r, --randomize   randomize a new playlist with <integer> tracks
        -c, --copy        copy the current track to location <string> 
        -f, --favorite    favorize the current track. If no name for the
                          playlist is given, the 'genre' id3-tag is used
        -l, --listalbums  list all albums by <string> or current artist
        -s, --show        show current playlist
        -p, --play        play the number <integer> track in playlist
        -a, --add         add playlist <string> and play it
        -m, --monitor     monitor MPD for song changes, output on STDOUT
       -ly, --lyrics      show lyrics for the current song
        -q, --queue       queue <integer> tracks in playlist
        -e, --external    list all tracks in external playlist <string>
       -ct, --ctrl        spawn the interactive pimpd shell 
      -spl, --search-pl   search the active playlist for <pattern>
      -sdb, --search-db   search the database for <pattern> and add the 
                          results to active playlist
        -n, --nocolor     dont use colorized output

        -h, --help        show this help

    PATTERN is Perl RE: '(foo|bar)', '(foo)?bar', 'foobarb.*', 'foo(d+)'


To install the dependencies:

    # ./INSTALL_MODULES

or use your package manager of choice.
In archlinux, you could just use:
    $ yaourt -S perl-html-tokeparser-simple perl-audio-mpd perl-libwww perl-text-wrapi18n

To install pimpd:
  Copy the configuration file to either /etc/pimpd.conf or
  $XDG_CONFIG_HOME/pimpd/config.pl

  Copy pimpd.pl to /usr/bin or any other location you prefer in your $PATH

Dont forget to edit the configuration file.

License
=======
Copyright (C) 2010 trapd00r

This program is free software; you can redistribute it and/or modify it under
the terms of the GNU General Public License, version 2, as published by the
Free Software Foundation

              
