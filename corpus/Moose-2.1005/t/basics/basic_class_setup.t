#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;


{
    package Foo;
    use Moose;
    use Moose::Util::TypeConstraints;
}

can_ok('Foo', 'meta');
isa_ok(Foo->meta, 'Moose::Meta::Class');

ok(Foo->meta->has_method('meta'), '... we got the &meta method');
ok(Foo->isa('Moose::Object'), '... Foo is automagically a Moose::Object');

isnt( exception {
   Foo->meta->has_method()
}, undef, '... has_method requires an arg' );

can_ok('Foo', 'does');

foreach my $function (qw(
                         extends
                         has
                         before after around
                         blessed confess
                         type subtype as where
                         coerce from via
                         find_type_constraint
                         )) {
    ok(!Foo->meta->has_method($function), '... the meta does not treat "' . $function . '" as a method');
}

foreach my $import (qw(
    blessed
    try
    catch
    in_global_destruction
)) {
    ok(!Moose::Object->can($import), "no namespace pollution in Moose::Object ($import)" );

    local $TODO = $import eq 'blessed' ? "no automatic namespace cleaning yet" : undef;
    ok(!Foo->can($import), "no namespace pollution in Moose::Object ($import)" );
}

done_testing;
