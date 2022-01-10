#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::Moose;

{
    package Foo;
    use Moose;

    has foo => (
        is        => 'ro',
        isa       => 'Maybe[Int]',
        default   => undef,
        predicate => 'has_foo',
    );
}

with_immutable {
    is(Foo->new->foo, undef);
    ok(Foo->new->has_foo);
} 'Foo';

done_testing;
