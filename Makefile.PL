#!/usr/bin/perl
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME => 'pimpd',
    DISTNAME => 'pimpd',
#    PMLIBDIRS => ['lib'],
    ABSTRACT => 'Perl Interface for the Music Player Daemon',
    AUTHOR => 'Magnus Woldrich <trapd00r@trapd00r.se',
    EXE_FILES => ['pimpd'],
    LICENSE => "GPLv2",
    MIN_PERL_VERSION => 5.000,
    PREREQ_PM => {
        'LWP::Simple'              => 0,
        'Audio::MPD'               => 0,
        'List::Util'               => 0,
        'HTML::TokeParser::Simple' => 0,
        'Text::Autoformat'         => 0,
    },
);


