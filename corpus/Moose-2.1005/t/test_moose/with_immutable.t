#!/usr/bin/perl

use strict;
use warnings;

use Test::Builder::Tester;
use Test::More;

plan skip_all => 'These tests are only for Test::Builder 0.9x'
    if Test::Builder->VERSION >= 1.005;

use Test::Moose;

{
    package Foo;
    use Moose;
}

{
    package Bar;
    use Moose;
}

package main;

test_out("ok 1", "not ok 2");
test_fail(+2);
my $ret = with_immutable {
    ok(Foo->meta->is_mutable);
} qw(Foo);
test_test('with_immutable failure');
ok(!$ret, "one of our tests failed");

test_out("ok 1", "ok 2");
$ret = with_immutable {
    ok(Bar->meta->find_method_by_name('new'));
} qw(Bar);
test_test('with_immutable success');
ok($ret, "all tests succeeded");

done_testing;
