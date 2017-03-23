#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Moose qw(does_ok);

{
    package Foo::Trait::Class;
    use Moose::Role;
}

{
    package Foo::Trait::Attribute;
    use Moose::Role;
}

{
    package Foo::Role::Base;
    use Moose::Role;
}

{
    package Foo::Exporter;
    use Moose::Exporter;

    Moose::Exporter->setup_import_methods(
        class_metaroles => {
            class     => ['Foo::Trait::Class'],
            attribute => ['Foo::Trait::Attribute'],
        },
        role_metaroles   => { role => ['Foo::Trait::Class'] },
        base_class_roles => ['Foo::Role::Base'],
    );
}

{
    package Foo;
    use Moose;
    Foo::Exporter->import;

    has foo => (is => 'ro');

    ::does_ok(Foo->meta, 'Foo::Trait::Class');
    ::does_ok(Foo->meta->get_attribute('foo'), 'Foo::Trait::Attribute');
    ::does_ok('Foo', 'Foo::Role::Base');
}

{
    package Foo::Exporter::WithMoose;
    use Moose ();
    use Moose::Exporter;

    my ( $import, $unimport, $init_meta )
        = Moose::Exporter->build_import_methods(
        also            => 'Moose',
        class_metaroles => {
            class     => ['Foo::Trait::Class'],
            attribute => ['Foo::Trait::Attribute'],
        },
        base_class_roles => ['Foo::Role::Base'],
        install          => [qw(import unimport)],
        );

    sub init_meta {
        my $package = shift;
        my %options = @_;
        ::pass('custom init_meta was called');
        Moose->init_meta(%options);
        return $package->$init_meta(%options);
    }
}

{
    package Foo2;
    Foo::Exporter::WithMoose->import;

    has(foo => (is => 'ro'));

    ::isa_ok('Foo2', 'Moose::Object');
    ::isa_ok(Foo2->meta, 'Moose::Meta::Class');
    ::does_ok(Foo2->meta, 'Foo::Trait::Class');
    ::does_ok(Foo2->meta->get_attribute('foo'), 'Foo::Trait::Attribute');
    ::does_ok('Foo2', 'Foo::Role::Base');
}

{
    package Foo::Role;
    use Moose::Role;
    Foo::Exporter->import;

    ::does_ok(Foo::Role->meta, 'Foo::Trait::Class');
}

{
    package Foo::Exporter::WithMooseRole;
    use Moose::Role ();
    use Moose::Exporter;

    my ( $import, $unimport, $init_meta )
        = Moose::Exporter->build_import_methods(
        also           => 'Moose::Role',
        role_metaroles => {
            role      => ['Foo::Trait::Class'],
            attribute => ['Foo::Trait::Attribute'],
        },
        install => [qw(import unimport)],
        );

    sub init_meta {
        my $package = shift;
        my %options = @_;
        ::pass('custom init_meta was called');
        Moose::Role->init_meta(%options);
        return $package->$init_meta(%options);
    }
}

{
    package Foo2::Role;
    Foo::Exporter::WithMooseRole->import;

    ::isa_ok(Foo2::Role->meta, 'Moose::Meta::Role');
    ::does_ok(Foo2::Role->meta, 'Foo::Trait::Class');
}

done_testing;
