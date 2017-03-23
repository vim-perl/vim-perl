#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;


{
    package Foo::Role;
    use Moose::Role;
    use Moose::Util::TypeConstraints;

    # if does() exists on its own, then
    # we create a type constraint for
    # it, just as we do for isa()
    has 'bar' => (is => 'rw', does => 'Bar::Role');
    has 'baz' => (
        is   => 'rw',
        does => role_type('Bar::Role')
    );

    package Foo::Class;
    use Moose;

    with 'Foo::Role';

    package Bar::Role;
    use Moose::Role;

    # if isa and does appear together, then see if Class->does(Role)
    # if it does work... then the does() check is actually not needed
    # since the isa() check will imply the does() check
    has 'foo' => (is => 'rw', isa => 'Foo::Class', does => 'Foo::Role');

    package Bar::Class;
    use Moose;

    with 'Bar::Role';
}

my $foo = Foo::Class->new;
isa_ok($foo, 'Foo::Class');

my $bar = Bar::Class->new;
isa_ok($bar, 'Bar::Class');

is( exception {
    $foo->bar($bar);
}, undef, '... bar passed the type constraint okay' );

isnt( exception {
    $foo->bar($foo);
}, undef, '... foo did not pass the type constraint okay' );

is( exception {
    $foo->baz($bar);
}, undef, '... baz passed the type constraint okay' );

isnt( exception {
    $foo->baz($foo);
}, undef, '... foo did not pass the type constraint okay' );

is( exception {
    $bar->foo($foo);
}, undef, '... foo passed the type constraint okay' );



# some error conditions

{
    package Baz::Class;
    use Moose;

    # if isa and does appear together, then see if Class->does(Role)
    # if it does not,.. we have a conflict... so we die loudly
    ::isnt( ::exception {
        has 'foo' => (isa => 'Foo::Class', does => 'Bar::Class');
    }, undef, '... cannot have a does() which is not done by the isa()' );
}

{
    package Bling;
    use strict;
    use warnings;

    sub bling { 'Bling::bling' }

    package Bling::Bling;
    use Moose;

    # if isa and does appear together, then see if Class->does(Role)
    # if it does not,.. we have a conflict... so we die loudly
    ::isnt( ::exception {
        has 'foo' => (isa => 'Bling', does => 'Bar::Class');
    }, undef, '... cannot have a isa() which is cannot does()' );
}

done_testing;
