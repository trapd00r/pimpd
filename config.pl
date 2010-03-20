# pimpd configuration file
# Location should be $XDG_CONFIG_HOME/pimpd/config.pl or /etc/pimpd.conf

# As specified in mpd.conf
our $basedir      = '/mnt/Music_1';
our $playlist_dir = '/mnt/Music_1/Playlists';
# If no name is specified for playlist, and track is missing id3-field
# 'genre', use this.
our $fallback_playlist = 'random';
# Portable player mountpoint
our $portable     = '/mnt/mp3/MUSIC'; 

# ssh credentials (optional)
our $remote_host  = undef;
our $remote_pass  = 'mpd_pass';
our $remote_user  = 'ssh_user';

# If you never want any coloured output, set this to 1
our $opt_color    = 0;
1;
