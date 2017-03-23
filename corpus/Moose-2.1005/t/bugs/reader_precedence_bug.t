#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

{
    package Foo;
    use Moose;
    has 'foo' => ( is => 'ro', reader => 'get_foo' );
}

{
    my $foo = Foo->new(foo => 10);
    my $reader = $foo->meta->get_attribute('foo')->reader;
    is($reader, 'get_foo',
       'reader => "get_foo" has correct presedence');
    can_ok($foo, 'get_foo');
    is($foo->$reader, 10, "Reader works as expected");
}

done_testing;
