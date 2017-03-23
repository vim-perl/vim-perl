#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;

{
    package Class::Vacuum::Innards;
    use Moose;

    package Class::Vacuum;
    use Moose ();
    use Moose::Exporter;

    sub meta_lookup { $_[0] }

    BEGIN {
        Moose::Exporter->setup_import_methods(
            also        => 'Moose',
            meta_lookup => sub { Class::MOP::class_of('Class::Vacuum::Innards') },
            with_meta   => ['meta_lookup'],
        );
    }
}

{
    package Victim;
    BEGIN { Class::Vacuum->import };

    has star_rod => (
        is => 'ro',
    );

    ::is(meta_lookup, Class::Vacuum::Innards->meta, "right meta_lookup");
}

ok(Class::Vacuum::Innards->can('star_rod'), 'Vacuum stole the star_rod method');
ok(!Victim->can('star_rod'), 'Victim does not get it at all');

{
    package Class::Vacuum::Reexport;
    use Moose::Exporter;

    BEGIN {
        Moose::Exporter->setup_import_methods(also => 'Class::Vacuum');
    }
}

{
    package Victim2;
    BEGIN { Class::Vacuum::Reexport->import }

    has parasol => (
        is => 'ro',
    );

    ::is(meta_lookup, Class::Vacuum::Innards->meta, "right meta_lookup");
}

ok(Class::Vacuum::Innards->can('parasol'), 'Vacuum stole the parasol method');
ok(!Victim2->can('parasol'), 'Victim does not get it at all');

done_testing;

