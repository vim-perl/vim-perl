#!/usr/bin/perl

use strict;
use warnings;

use Test::Builder::Tester;
use Test::More;

use Test::Moose;

{
    package Foo;
    use Moose::Role;
}

{
    package Bar;
    use Moose;

    with qw/Foo/;
}

{
    package Baz;
    use Moose;
}

# class ok

test_out('ok 1 - does_ok class');

does_ok('Bar','Foo','does_ok class');

# class fail

test_out ('not ok 2 - does_ok class fail');
test_fail (+2);

does_ok('Baz','Foo','does_ok class fail');

# object ok

my $bar = Bar->new;

test_out ('ok 3 - does_ok object');

does_ok ($bar,'Foo','does_ok object');

# object fail

my $baz = Baz->new;

test_out ('not ok 4 - does_ok object fail');
test_fail (+2);

does_ok ($baz,'Foo','does_ok object fail');

test_test ('does_ok');

done_testing;
