#!/usr/bin/perl

use strict;
use warnings;

my $num_iterations = shift || 100;

{
    package Foo;
    use Moose;

    has 'default'         => (is => 'rw', default => 10);
    has 'default_sub'     => (is => 'rw', default => sub { [] });
    has 'lazy'            => (is => 'rw', default => 10, lazy => 1);
    has 'required'        => (is => 'rw', required => 1);
    has 'weak_ref'        => (is => 'rw', weak_ref => 1);
    has 'type_constraint' => (is => 'rw', isa => 'ArrayRef');
}

foreach (0 .. $num_iterations) {
    my $foo = Foo->new(
        required        => 'BAR',
        type_constraint => [],
        weak_ref        => {},
    );
}