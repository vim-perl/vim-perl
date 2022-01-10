#!/usr/bin/perl
use strict;
use warnings;

use Test::More;

# test role and class
package SomeRole;
use Moose::Role;

requires 'foo';

package SomeClass;
use Moose;
has 'foo' => (is => 'rw');
with 'SomeRole';

package main;

#my $c = SomeClass->new;
#isa_ok( $c, 'SomeClass');

for my $modifier_type (qw[ before around after ]) {
    my $get_func = "get_${modifier_type}_method_modifiers";
    my @mms = eval{ SomeRole->meta->$get_func('foo') };
    is($@, '', "$get_func for no method mods does not die");
    is(scalar(@mms),0,'is an empty list');
}

done_testing;
