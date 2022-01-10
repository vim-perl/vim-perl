#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;


{
    package My::Meta;

    use Moose;

    extends 'Moose::Meta::Class';

    has 'meta_size' => (
        is  => 'rw',
        isa => 'Int',
    );
}

is( exception {
    My::Meta->meta()->make_immutable(debug => 0)
}, undef, '... can make a meta class immutable' );

done_testing;
