#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

my $called;
{
    package Foo;
    use Moose;

    sub BUILD { $called++ }
}

Foo->new;
is($called, 1, "BUILD called from ->new");
$called = 0;
Foo->meta->new_object;
is($called, 1, "BUILD called from ->meta->new_object");

done_testing;
