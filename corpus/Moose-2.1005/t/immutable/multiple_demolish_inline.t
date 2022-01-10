#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;


{
    package Foo;
    use Moose;

    has 'foo' => (is => 'rw', isa => 'Int');

    sub DEMOLISH { }
}

{
    package Bar;
    use Moose;

    extends qw(Foo);
    has 'bar' => (is => 'rw', isa => 'Int');

    sub DEMOLISH { }
}

is( exception {
    Bar->new();
}, undef, 'Bar->new()' );

is( exception {
    Bar->meta->make_immutable;
}, undef, 'Bar->meta->make_immutable' );

is( Bar->meta->get_method('DESTROY')->package_name, 'Bar',
    'Bar has a DESTROY method in the Bar class (not inherited)' );

is( exception {
    Foo->meta->make_immutable;
}, undef, 'Foo->meta->make_immutable' );

is( Foo->meta->get_method('DESTROY')->package_name, 'Foo',
    'Foo has a DESTROY method in the Bar class (not inherited)' );

done_testing;
