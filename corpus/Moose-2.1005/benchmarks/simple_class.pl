#!/usr/bin/perl

use strict;
use warnings;

use Benchmark::Forking qw[cmpthese];

=pod

This compares the burden of a basic Moose
class to a basic Class::MOP class.

It is worth noting that the basic Moose
class will also create a type constraint
as well as export many subs, so this comparison
is really not fair :)

=cut

cmpthese(5_000,
    {
        'w/out_moose' => sub {
            eval 'package Bar; use metaclass;';
        },
        'w_moose' => sub {
            eval 'package Baz; use Moose;';
        },
    }
);

1;