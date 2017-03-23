use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Regexp::Debugger',
    AUTHOR              => 'Damian Conway <DCONWAY@CPAN.org>',
    VERSION_FROM        => 'lib/Regexp/Debugger.pm',
    ABSTRACT_FROM       => 'lib/Regexp/Debugger.pm',
    MIN_PERL_VERSION    => 5.010001,
    PL_FILES            => {},
    EXE_FILES           => [ 'bin/rxrx' ],
    PREREQ_PM => {
        'Test::More' => 0,
        'version'    => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Regexp-Debugger-*' },
);
