#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;


{
    package Foo;
    use Moose;

    has 'bar' => (is => 'ro', required => 1);
    has 'baz' => (is => 'rw',  default => 100, required => 1);
    has 'boo' => (is => 'rw', lazy => 1, default => 50, required => 1);
}

{
    my $foo = Foo->new(bar => 10, baz => 20, boo => 100);
    isa_ok($foo, 'Foo');

    is($foo->bar, 10, '... got the right bar');
    is($foo->baz, 20, '... got the right baz');
    is($foo->boo, 100, '... got the right boo');
}

{
    my $foo = Foo->new(bar => 10, boo => 5);
    isa_ok($foo, 'Foo');

    is($foo->bar, 10, '... got the right bar');
    is($foo->baz, 100, '... got the right baz');
    is($foo->boo, 5, '... got the right boo');
}

{
    my $foo = Foo->new(bar => 10);
    isa_ok($foo, 'Foo');

    is($foo->bar, 10, '... got the right bar');
    is($foo->baz, 100, '... got the right baz');
    is($foo->boo, 50, '... got the right boo');
}

#Yeah.. this doesn't work like this anymore, see below. (groditi)
#throws_ok {
#    Foo->new(bar => 10, baz => undef);
#} qr/^Attribute \(baz\) is required and cannot be undef/, '... must supply all the required attribute';

#throws_ok {
#    Foo->new(bar => 10, boo => undef);
#} qr/^Attribute \(boo\) is required and cannot be undef/, '... must supply all the required attribute';

is( exception {
    Foo->new(bar => 10, baz => undef);
}, undef, '... undef is a valid attribute value' );

is( exception {
    Foo->new(bar => 10, boo => undef);
}, undef, '... undef is a valid attribute value' );


like( exception {
    Foo->new;
}, qr/^Attribute \(bar\) is required/, '... must supply all the required attribute' );

done_testing;
