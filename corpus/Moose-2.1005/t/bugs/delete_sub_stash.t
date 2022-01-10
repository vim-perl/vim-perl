#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use Moose ();

{
    package Foo;
    sub bar { 'BAR' }
}

my $method = \&Foo::bar;

{
    no strict 'refs';
    delete ${'::'}{'Foo::'};
}

my $meta = Moose::Meta::Class->create('Bar');
$meta->add_method(bar => $method);
is(Bar->bar, 'BAR');

done_testing;
