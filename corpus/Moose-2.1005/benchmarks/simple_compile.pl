#!/usr/bin/perl

use strict;
use warnings;

use Benchmark::Forking qw[cmpthese];

=pod

This compare the overhead of Class::MOP
to the overhead of Moose.

The goal here is to see how much more
startup cost Moose adds to Class::MOP.

NOTE:
This benchmark may not be all that
relevant really, but it's helpful to
see maybe.

=cut

cmpthese(5_000,
    {
        'w/out_moose' => sub {
            eval 'use Class::MOP;';
        },
        'w_moose' => sub {
            eval 'use Moose;';
        },
    }
);

1;