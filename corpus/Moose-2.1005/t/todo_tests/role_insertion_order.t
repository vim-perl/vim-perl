#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

{
    package Foo::Role;
    use Moose::Role;
    has 'a' => (is => 'ro');
    has 'b' => (is => 'ro');
    has 'c' => (is => 'ro');
}

{
    package Foo;
    use Moose;
    has 'd' => (is => 'ro');
    with 'Foo::Role';
    has 'e' => (is => 'ro');
}

my %role_insertion_order = (
    a => 0,
    b => 1,
    c => 2,
);

is_deeply({ map { $_->name => $_->insertion_order } map { Foo::Role->meta->get_attribute($_) } Foo::Role->meta->get_attribute_list }, \%role_insertion_order, "right insertion order within the role");

my %class_insertion_order = (
    d => 0,
    a => 1,
    b => 2,
    c => 3,
    e => 4,
);

{ local $TODO = "insertion order is lost during role application";
is_deeply({ map { $_->name => $_->insertion_order } Foo->meta->get_all_attributes }, \%class_insertion_order, "right insertion order within the class");
}

done_testing;
