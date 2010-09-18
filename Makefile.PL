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
    MAN1PODS  => {
      'pimpd' => 'blib/man1/pimpd.1',
    },
    PREREQ_PM => {
        'Audio::MPD'               => 0,
    },
);


