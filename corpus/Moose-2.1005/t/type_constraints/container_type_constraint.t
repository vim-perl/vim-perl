#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Moose::Util::TypeConstraints;
use Moose::Meta::TypeConstraint::Parameterized;

# Array of Ints

my $array_of_ints = Moose::Meta::TypeConstraint::Parameterized->new(
    name           => 'ArrayRef[Int]',
    parent         => find_type_constraint('ArrayRef'),
    type_parameter => find_type_constraint('Int'),
);
isa_ok($array_of_ints, 'Moose::Meta::TypeConstraint::Parameterized');
isa_ok($array_of_ints, 'Moose::Meta::TypeConstraint');

ok($array_of_ints->check([ 1, 2, 3, 4 ]), '... [ 1, 2, 3, 4 ] passed successfully');
ok(!$array_of_ints->check([qw/foo bar baz/]), '... [qw/foo bar baz/] failed successfully');
ok(!$array_of_ints->check([ 1, 2, 3, qw/foo bar/]), '... [ 1, 2, 3, qw/foo bar/] failed successfully');

ok(!$array_of_ints->check(1), '... 1 failed successfully');
ok(!$array_of_ints->check({}), '... {} failed successfully');
ok(!$array_of_ints->check(sub { () }), '... sub { () } failed successfully');

# Hash of Ints

my $hash_of_ints = Moose::Meta::TypeConstraint::Parameterized->new(
    name           => 'HashRef[Int]',
    parent         => find_type_constraint('HashRef'),
    type_parameter => find_type_constraint('Int'),
);
isa_ok($hash_of_ints, 'Moose::Meta::TypeConstraint::Parameterized');
isa_ok($hash_of_ints, 'Moose::Meta::TypeConstraint');

ok($hash_of_ints->check({ one => 1, two => 2, three => 3 }), '... { one => 1, two => 2, three => 3 } passed successfully');
ok(!$hash_of_ints->check({ 1 => 'one', 2 => 'two', 3 => 'three' }), '... { 1 => one, 2 => two, 3 => three } failed successfully');
ok(!$hash_of_ints->check({ 1 => 'one', 2 => 'two', three => 3 }), '... { 1 => one, 2 => two, three => 3 } failed successfully');

ok(!$hash_of_ints->check(1), '... 1 failed successfully');
ok(!$hash_of_ints->check([]), '... [] failed successfully');
ok(!$hash_of_ints->check(sub { () }), '... sub { () } failed successfully');

# Array of Array of Ints

my $array_of_array_of_ints = Moose::Meta::TypeConstraint::Parameterized->new(
    name           => 'ArrayRef[ArrayRef[Int]]',
    parent         => find_type_constraint('ArrayRef'),
    type_parameter => $array_of_ints,
);
isa_ok($array_of_array_of_ints, 'Moose::Meta::TypeConstraint::Parameterized');
isa_ok($array_of_array_of_ints, 'Moose::Meta::TypeConstraint');

ok($array_of_array_of_ints->check(
    [[ 1, 2, 3 ], [ 4, 5, 6 ]]
), '... [[ 1, 2, 3 ], [ 4, 5, 6 ]] passed successfully');
ok(!$array_of_array_of_ints->check(
    [[ 1, 2, 3 ], [ qw/foo bar/ ]]
), '... [[ 1, 2, 3 ], [ qw/foo bar/ ]] failed successfully');

{
    my $anon_type = Moose::Util::TypeConstraints::find_or_parse_type_constraint('ArrayRef[Foo]');
    isa_ok( $anon_type, 'Moose::Meta::TypeConstraint::Parameterized' );

    my $param_type = $anon_type->type_parameter;
    isa_ok( $param_type, 'Moose::Meta::TypeConstraint::Class' );
}

done_testing;
