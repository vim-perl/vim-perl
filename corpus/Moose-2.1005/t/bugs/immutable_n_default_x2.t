#!/usr/bin/perl

use strict;
use warnings;

use Test::More;


{
    package Foo;
    use Moose;

    our $foo_default_called = 0;

    has foo => (
        is      => 'rw',
        isa     => 'Str',
        default => sub { $foo_default_called++; 'foo' },
    );

    our $bar_default_called = 0;

    has bar => (
        is      => 'rw',
        isa     => 'Str',
        lazy    => 1,
        default => sub { $bar_default_called++; 'bar' },
    );

    __PACKAGE__->meta->make_immutable;
}

my $foo = Foo->new();

is($Foo::foo_default_called, 1, "foo default was only called once during constructor");

$foo->bar();

is($Foo::bar_default_called, 1, "bar default was only called once when lazy attribute is accessed");

done_testing;
