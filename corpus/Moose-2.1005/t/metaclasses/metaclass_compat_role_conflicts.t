#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

BEGIN {
    package My::Meta::Role1;
    use Moose::Role;
    sub foo { 'Role1' }
}
BEGIN {
    package My::Meta::Role2;
    use Moose::Role;
    with 'My::Meta::Role1';
    sub foo { 'Role2' }
}
BEGIN {
    package My::Extension;
    use Moose::Exporter;
    Moose::Exporter->setup_import_methods(
        class_metaroles => {
            class => ['My::Meta::Role2'],
        },
    );
    $INC{'My/Extension.pm'} = __FILE__;
}
BEGIN {
    package My::Meta::Role3;
    use Moose::Role;
}
BEGIN {
    package My::Extension2;
    use Moose::Exporter;
    Moose::Exporter->setup_import_methods(
        class_metaroles => {
            class => ['My::Meta::Role3'],
        },
    );
    $INC{'My/Extension2.pm'} = __FILE__;
}

{
    package My::Class1;
    use Moose;
    use My::Extension;
}

is(My::Class1->new->meta->foo, 'Role2');

{
    package My::Class2;
    use Moose;
    use My::Extension2;
}
{
    package My::Class3;
    use Moose;
    use My::Extension;
    extends 'My::Class2';
}

is(My::Class3->new->meta->foo, 'Role2');

done_testing;
