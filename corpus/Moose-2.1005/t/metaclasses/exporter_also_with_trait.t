#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::Moose;

BEGIN {
    package My::Meta::Role;
    use Moose::Role;
    $INC{'My/Meta/Role.pm'} = __FILE__;
}

BEGIN {
    package My::Exporter;
    use Moose::Exporter;

    Moose::Exporter->setup_import_methods(
        also => ['Moose'],
        class_metaroles => {
            class => ['My::Meta::Role'],
        },
    );
    $INC{'My/Exporter.pm'} = __FILE__;
}

{
    package My::Class;
    use My::Exporter;
}

{
    my $meta = My::Class->meta;
    isa_ok($meta, 'Moose::Meta::Class');
    does_ok($meta, 'My::Meta::Role');
}

done_testing;
