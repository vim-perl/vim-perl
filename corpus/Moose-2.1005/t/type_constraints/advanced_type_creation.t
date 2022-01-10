#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Moose::Util::TypeConstraints;
use Moose::Meta::TypeConstraint::Parameterized;

my $r = Moose::Util::TypeConstraints->get_type_constraint_registry;

## Containers in unions ...

# Array of Ints or Strings

my $array_of_ints_or_strings = Moose::Util::TypeConstraints::create_parameterized_type_constraint('ArrayRef[Int|Str]');
isa_ok($array_of_ints_or_strings, 'Moose::Meta::TypeConstraint::Parameterized');

ok($array_of_ints_or_strings->check([ 1, 'two', 3 ]), '... this passed the type check');
ok($array_of_ints_or_strings->check([ 1, 2, 3 ]), '... this passed the type check');
ok($array_of_ints_or_strings->check([ 'one', 'two', 'three' ]), '... this passed the type check');

ok(!$array_of_ints_or_strings->check([ 1, [], 'three' ]), '... this didnt pass the type check');

$r->add_type_constraint($array_of_ints_or_strings);

# Array of Ints or HashRef

my $array_of_ints_or_hash_ref = Moose::Util::TypeConstraints::create_parameterized_type_constraint('ArrayRef[Int | HashRef]');
isa_ok($array_of_ints_or_hash_ref, 'Moose::Meta::TypeConstraint::Parameterized');

ok($array_of_ints_or_hash_ref->check([ 1, {}, 3 ]), '... this passed the type check');
ok($array_of_ints_or_hash_ref->check([ 1, 2, 3 ]), '... this passed the type check');
ok($array_of_ints_or_hash_ref->check([ {}, {}, {} ]), '... this passed the type check');

ok(!$array_of_ints_or_hash_ref->check([ {}, [], 3 ]), '... this didnt pass the type check');

$r->add_type_constraint($array_of_ints_or_hash_ref);

# union of Arrays of Str | Int or Arrays of Int | Hash

# we can't build this using the simplistic parser
# we have, so we have to do it by hand - SL

my $pure_insanity = Moose::Util::TypeConstraints::create_type_constraint_union('ArrayRef[Int|Str] | ArrayRef[Int | HashRef]');
isa_ok($pure_insanity, 'Moose::Meta::TypeConstraint::Union');

ok($pure_insanity->check([ 1, {}, 3 ]), '... this passed the type check');
ok($pure_insanity->check([ 1, 'Str', 3 ]), '... this passed the type check');

ok(!$pure_insanity->check([ 1, {}, 'foo' ]), '... this didnt pass the type check');
ok(!$pure_insanity->check([ [], {}, 1 ]), '... this didnt pass the type check');

## Nested Containers ...

# Array of Ints

my $array_of_ints = Moose::Util::TypeConstraints::create_parameterized_type_constraint('ArrayRef[Int]');
isa_ok($array_of_ints, 'Moose::Meta::TypeConstraint::Parameterized');
isa_ok($array_of_ints, 'Moose::Meta::TypeConstraint');

ok($array_of_ints->check([ 1, 2, 3, 4 ]), '... [ 1, 2, 3, 4 ] passed successfully');
ok(!$array_of_ints->check([qw/foo bar baz/]), '... [qw/foo bar baz/] failed successfully');
ok(!$array_of_ints->check([ 1, 2, 3, qw/foo bar/]), '... [ 1, 2, 3, qw/foo bar/] failed successfully');

ok(!$array_of_ints->check(1), '... 1 failed successfully');
ok(!$array_of_ints->check({}), '... {} failed successfully');
ok(!$array_of_ints->check(sub { () }), '... sub { () } failed successfully');

# Array of Array of Ints

my $array_of_array_of_ints = Moose::Util::TypeConstraints::create_parameterized_type_constraint('ArrayRef[ArrayRef[Int]]');
isa_ok($array_of_array_of_ints, 'Moose::Meta::TypeConstraint::Parameterized');
isa_ok($array_of_array_of_ints, 'Moose::Meta::TypeConstraint');

ok($array_of_array_of_ints->check(
    [[ 1, 2, 3 ], [ 4, 5, 6 ]]
), '... [[ 1, 2, 3 ], [ 4, 5, 6 ]] passed successfully');
ok(!$array_of_array_of_ints->check(
    [[ 1, 2, 3 ], [ qw/foo bar/ ]]
), '... [[ 1, 2, 3 ], [ qw/foo bar/ ]] failed successfully');

# Array of Array of Array of Ints

my $array_of_array_of_array_of_ints = Moose::Util::TypeConstraints::create_parameterized_type_constraint('ArrayRef[ArrayRef[ArrayRef[Int]]]');
isa_ok($array_of_array_of_array_of_ints, 'Moose::Meta::TypeConstraint::Parameterized');
isa_ok($array_of_array_of_array_of_ints, 'Moose::Meta::TypeConstraint');

ok($array_of_array_of_array_of_ints->check(
    [[[ 1, 2, 3 ], [ 4, 5, 6 ]], [[ 7, 8, 9 ]]]
), '... [[[ 1, 2, 3 ], [ 4, 5, 6 ]], [[ 7, 8, 9 ]]] passed successfully');
ok(!$array_of_array_of_array_of_ints->check(
    [[[ 1, 2, 3 ]], [[ qw/foo bar/ ]]]
), '... [[[ 1, 2, 3 ]], [[ qw/foo bar/ ]]] failed successfully');

done_testing;
