#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Test::Requires {
    'Test::Output' => '0.01', # skip all if not installed
};

{
    package Foo;
    use Moose;
    __PACKAGE__->meta->make_immutable;
}

{
    package Bar;
    use Moose;

    extends 'Foo';

    __PACKAGE__->meta->make_immutable;
    __PACKAGE__->meta->make_mutable;


    # This actually is testing for a bug in Class::MOP that cause
    # Moose::Meta::Method::Constructor to spit out a warning when it
    # shouldn't have done so. The bug was fixed in CMOP 0.75.
    ::stderr_unlike(
        sub { Bar->meta->make_immutable },
        qr/Not inlining a constructor/,
        'no warning that Bar may not have an inlined constructor'
    );
}

done_testing;
