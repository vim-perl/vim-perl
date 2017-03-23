#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

=pod

This is a test for a bug found by Purge on #moose:
The code:

  subtype Stuff
    => as Object
    => where { ... }

will break if the Object:: namespace exists. So the
solution is to quote 'Object', like so:

  subtype Stuff
    => as 'Object'
    => where { ... }

Moose 0.03 did this, now it doesn't, so all should
be well from now on.

=cut

{ package Object::Test; }

{
    package Foo;
    ::use_ok('Moose');
}

done_testing;
