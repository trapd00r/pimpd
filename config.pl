# pimpd configuration file
# Location should be $XDG_CONFIG_HOME/pimpd/config.pl or /etc/pimpd.conf

# As specified in mpd.conf
our $basedir      = '/mnt/Music_1';
our $playlist_dir = '/mnt/Music_1/Playlists';

# If no name is specified for playlist, and track is missing id3-field
# 'genre', use this.
our $fallback_playlist = 'random';

# Used for history. Use standard unix tools to have fun with it.
# i.e; for x in $(tail -15 /mnt/Music_1/Playlists/history.m3u); \
#      do cp /mnt/Music_1/$x /mnt/mp3; done
# to copy the 15 latest tracks to your mp3-player
our $history_playlist  = 'loved.history';

# Default location for the --copy command.
# Your portable player, /tmp/burn, or what you prefer
our $portable     = '/mnt/mp3/MUSIC'; 

# ssh credentials (optional, for the --copy command)
our $remote_host  = undef;
our $remote_pass  = 'mpd_pass';
our $remote_user  = 'ssh_user';

# colorscheme
our @clr;
$clr[0] = "\033[31m";
$clr[1] = "\033[31;1m";
$clr[2] = "\033[32m";
$clr[3] = "\033[32;1m";
$clr[4] = "\033[33m";
$clr[5] = "\033[34m";
$clr[6] = "\033[34;1m";
$clr[7] = "\033[36m";
$clr[8] = "\033[36;1m";
$clr[9] = "\033[0m";

# If you never want any coloured output, set this to 1
our $opt_color    = 0;
1;
