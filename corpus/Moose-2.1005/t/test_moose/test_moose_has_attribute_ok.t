#!/usr/bin/perl

use strict;
use warnings;

use Test::Builder::Tester;
use Test::More;

use Test::Moose;

{
    package Foo;
    use Moose;

    has 'foo', is => 'bare';
}

{
    package Bar;
    use Moose;

    extends 'Foo';

    has 'bar', is => 'bare';
}


test_out('ok 1 - ... has_attribute_ok(Foo, foo) passes');

has_attribute_ok('Foo', 'foo', '... has_attribute_ok(Foo, foo) passes');

test_out ('not ok 2 - ... has_attribute_ok(Foo, bar) fails');
test_fail (+2);

has_attribute_ok('Foo', 'bar', '... has_attribute_ok(Foo, bar) fails');

test_out('ok 3 - ... has_attribute_ok(Bar, foo) passes');

has_attribute_ok('Bar', 'foo', '... has_attribute_ok(Bar, foo) passes');

test_out('ok 4 - ... has_attribute_ok(Bar, bar) passes');

has_attribute_ok('Bar', 'bar', '... has_attribute_ok(Bar, bar) passes');

test_test ('has_attribute_ok');

done_testing;
