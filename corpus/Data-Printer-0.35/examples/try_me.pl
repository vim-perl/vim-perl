#!/usr/bin/env perl
use strict;
use warnings;
use Scalar::Util qw(weaken);

# This sample code is available to you so you
# can see Data::Printer working out of the box.
# It can be used as a quick way to test your
# color palette scheme!

package My::SampleClass;
sub new { bless {}, shift }
sub public_method { 42 }
sub _private_method { 'sample' }


package main;

my $obj = My::SampleClass->new;

my %sample = (
  number => 123.456,
  string => 'a string',
  array  => [ "foo\0has\tescapes", 6, undef ],
  hash   => {
    foo => 'bar',
    baz => 789,
  },
  regexp => qr/foo.*bar/i,
  glob   => \*STDOUT,
  code   => sub { return 42 },
  class  => $obj,
);

$sample{ref} = \%sample;
weaken $sample{ref};

use DDP; p %sample;

