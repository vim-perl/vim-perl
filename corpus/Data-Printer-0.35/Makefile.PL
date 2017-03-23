use strict;
use warnings;
use ExtUtils::MakeMaker;

my %options = (
    NAME                => 'Data::Printer',
    AUTHOR              => 'Breno G. de Oliveira <garu@cpan.org>',
    VERSION_FROM        => 'lib/Data/Printer.pm',
    ABSTRACT_FROM       => 'lib/Data/Printer.pm',
    LICENSE             => 'perl',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More'      => 0.88,
        'Term::ANSIColor' => 3.0,  # introduces 'bright_*' colors
        'Scalar::Util'    => 0,
        'version'         => 0.77, # handling VSTRINGS
        'Sort::Naturally' => 0,
        'Package::Stash'  => 0.30,
        'Carp'            => 0,
        'Clone::PP'       => 0,
        'File::HomeDir'   => 0.91, # introduces File::HomeDir::Test
        'File::Spec'      => 0,
        'File::Temp'      => 0,
        'Fcntl'           => 0,
        ($] >= 5.010
            ? () 
            : (
                'MRO::Compat' => 0.09,
                'Hash::Util::FieldHash::Compat' => 0.03,
              )
        ),
    },
    META_MERGE      => {
        resources => {
            license     =>      'http://dev.perl.org/licenses/',
            bugtracker  =>      'http://rt.cpan.org/NoAuth/Bugs.html?Dist=Data-Printer',
            repository  =>      'http://github.com/garu/Data-Printer',
        },
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Data-Printer-*' },
);


if ($^O =~ /Win32/i) {
    $options{PREREQ_PM}{'Win32::Console::ANSI'} = 1.0;
}


WriteMakefile( %options );

