#!/usr/bin/perl

use strict;
use warnings;

use Test::Builder::Tester;
use Test::More;

use Test::Moose;

{
    package Foo;
    use Moose;
}

{
    package Bar;
}

test_out('ok 1 - ... meta_ok(Foo) passes');

meta_ok('Foo', '... meta_ok(Foo) passes');

test_out ('not ok 2 - ... meta_ok(Bar) fails');
test_fail (+2);

meta_ok('Bar', '... meta_ok(Bar) fails');

test_test ('meta_ok');

done_testing;
