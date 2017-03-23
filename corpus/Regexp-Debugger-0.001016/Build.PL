use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Regexp::Debugger',
    license             => 'perl',
    dist_author         => 'Damian Conway <DCONWAY@CPAN.org>',
    dist_version_from   => 'lib/Regexp/Debugger.pm',
    requires => {
        'perl'       => 5.010001,
        'Test::More' => 0,
        'version'    => 0,
    },
    add_to_cleanup      => [ 'Regexp-Debugger-*' ],
);

$builder->create_build_script();
