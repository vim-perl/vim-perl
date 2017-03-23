#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Moose::Util::TypeConstraints;

## First, we check that the new regex parsing works

ok Moose::Util::TypeConstraints::_detect_parameterized_type_constraint(
    'ArrayRef[Str]') => 'detected correctly';

is_deeply
    [
    Moose::Util::TypeConstraints::_parse_parameterized_type_constraint(
        'ArrayRef[Str]')
    ],
    [ "ArrayRef", "Str" ] => 'Correctly parsed ArrayRef[Str]';

ok Moose::Util::TypeConstraints::_detect_parameterized_type_constraint(
    'ArrayRef[Str  ]') => 'detected correctly';

is_deeply
    [
    Moose::Util::TypeConstraints::_parse_parameterized_type_constraint(
        'ArrayRef[Str  ]')
    ],
    [ "ArrayRef", "Str" ] => 'Correctly parsed ArrayRef[Str  ]';

ok Moose::Util::TypeConstraints::_detect_parameterized_type_constraint(
    'ArrayRef[  Str]') => 'detected correctly';

is_deeply
    [
    Moose::Util::TypeConstraints::_parse_parameterized_type_constraint(
        'ArrayRef[  Str]')
    ],
    [ "ArrayRef", "Str" ] => 'Correctly parsed ArrayRef[  Str]';

ok Moose::Util::TypeConstraints::_detect_parameterized_type_constraint(
    'ArrayRef[  Str  ]') => 'detected correctly';

is_deeply
    [
    Moose::Util::TypeConstraints::_parse_parameterized_type_constraint(
        'ArrayRef[  Str  ]')
    ],
    [ "ArrayRef", "Str" ] => 'Correctly parsed ArrayRef[  Str  ]';

ok Moose::Util::TypeConstraints::_detect_parameterized_type_constraint(
    'ArrayRef[  HashRef[Int]  ]') => 'detected correctly';

is_deeply
    [
    Moose::Util::TypeConstraints::_parse_parameterized_type_constraint(
        'ArrayRef[  HashRef[Int]  ]')
    ],
    [ "ArrayRef", "HashRef[Int]" ] =>
    'Correctly parsed ArrayRef[  HashRef[Int]  ]';

ok Moose::Util::TypeConstraints::_detect_parameterized_type_constraint(
    'ArrayRef[  HashRef[Int  ]  ]') => 'detected correctly';

is_deeply
    [
    Moose::Util::TypeConstraints::_parse_parameterized_type_constraint(
        'ArrayRef[  HashRef[Int  ]  ]')
    ],
    [ "ArrayRef", "HashRef[Int  ]" ] =>
    'Correctly parsed ArrayRef[  HashRef[Int  ]  ]';

ok Moose::Util::TypeConstraints::_detect_parameterized_type_constraint(
    'ArrayRef[Int|Str]') => 'detected correctly';

is_deeply
    [
    Moose::Util::TypeConstraints::_parse_parameterized_type_constraint(
        'ArrayRef[Int|Str]')
    ],
    [ "ArrayRef", "Int|Str" ] => 'Correctly parsed ArrayRef[Int|Str]';

ok Moose::Util::TypeConstraints::_detect_parameterized_type_constraint(
    'ArrayRef[ArrayRef[Int]|Str]') => 'detected correctly';

is_deeply
    [
    Moose::Util::TypeConstraints::_parse_parameterized_type_constraint(
        'ArrayRef[ArrayRef[Int]|Str]')
    ],
    [ "ArrayRef", "ArrayRef[Int]|Str" ] =>
    'Correctly parsed ArrayRef[ArrayRef[Int]|Str]';

## creating names via subtype

ok my $r = Moose::Util::TypeConstraints->get_type_constraint_registry =>
    'Got registry object';

ok my $subtype_a1
    = subtype( 'subtype_a1' => as 'HashRef[Int]' ), => 'created subtype_a1';

ok my $subtype_a2
    = subtype( 'subtype_a2' => as 'HashRef[  Int]' ), => 'created subtype_a2';

ok my $subtype_a3
    = subtype( 'subtype_a2' => as 'HashRef[Int  ]' ), => 'created subtype_a2';

ok my $subtype_a4 = subtype( 'subtype_a2' => as 'HashRef[  Int  ]' ), =>
    'created subtype_a2';

is $subtype_a1->parent->name, $subtype_a2->parent->name => 'names match';

is $subtype_a1->parent->name, $subtype_a3->parent->name => 'names match';

is $subtype_a1->parent->name, $subtype_a4->parent->name => 'names match';

ok my $subtype_b1 = subtype( 'subtype_b1' => as 'HashRef[Int|Str]' ), =>
    'created subtype_b1';

ok my $subtype_b2 = subtype( 'subtype_b2' => as 'HashRef[Int | Str]' ), =>
    'created subtype_b2';

ok my $subtype_b3 = subtype( 'subtype_b3' => as 'HashRef[Str|Int]' ), =>
    'created subtype_b3';

is $subtype_b1->parent->name, $subtype_b2->parent->name => 'names match';

is $subtype_b1->parent->name, $subtype_b3->parent->name => 'names match';

is $subtype_b2->parent->name, $subtype_b3->parent->name => 'names match';

## testing via add_constraint

ok my $union1 = Moose::Util::TypeConstraints::create_type_constraint_union(
    'ArrayRef[Int|Str] | ArrayRef[Int | HashRef]') => 'Created Union1';

ok my $union2 = Moose::Util::TypeConstraints::create_type_constraint_union(
    'ArrayRef[  Int|Str] | ArrayRef[Int | HashRef]') => 'Created Union2';

ok my $union3 = Moose::Util::TypeConstraints::create_type_constraint_union(
    'ArrayRef[Int |Str   ] | ArrayRef[Int | HashRef  ]') => 'Created Union3';

is $union1->name, $union2->name, 'names match';

is $union1->name, $union3->name, 'names match';

is $union2->name, $union3->name, 'names match';

done_testing;
