#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;

use Moose::Util::TypeConstraints;

=pod

This tests demonstrates that Moose will not override
a preexisting type constraint of the same name when
making constraints for a Moose-class.

It also tests that an attribute which uses a 'Foo' for
its isa option will get the subtype Foo, and not a
type representing the Foo moose class.

=cut

BEGIN {
    # create this subtype first (in BEGIN)
    subtype Foo
        => as 'Value'
        => where { $_ eq 'Foo' };
}

{ # now seee if Moose will override it
    package Foo;
    use Moose;
}

my $foo_constraint = find_type_constraint('Foo');
isa_ok($foo_constraint, 'Moose::Meta::TypeConstraint');

is($foo_constraint->parent->name, 'Value', '... got the Value subtype for Foo');

ok($foo_constraint->check('Foo'), '... my constraint passed correctly');
ok(!$foo_constraint->check('Bar'), '... my constraint failed correctly');

{
    package Bar;
    use Moose;

    has 'foo' => (is => 'rw', isa => 'Foo');
}

my $bar = Bar->new;
isa_ok($bar, 'Bar');

is( exception {
    $bar->foo('Foo');
}, undef, '... checked the type constraint correctly' );

isnt( exception {
    $bar->foo(Foo->new);
}, undef, '... checked the type constraint correctly' );

done_testing;
