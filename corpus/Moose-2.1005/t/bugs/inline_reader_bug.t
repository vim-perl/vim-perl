#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;


=pod

This was a bug, but it is fixed now. This
test makes sure it does not creep back in.

=cut

{
    package Foo;
    use Moose;

    ::is( ::exception {
        has 'bar' => (
            is      => 'ro',
            isa     => 'Int',
            lazy    => 1,
            default => 10,
        );
    }, undef, '... this didnt die' );
}

done_testing;
