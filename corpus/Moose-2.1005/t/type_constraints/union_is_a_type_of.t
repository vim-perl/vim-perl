#!/usr/bin/perl

use strict;
use warnings;

use Test::Fatal;
use Test::More;

use Moose::Util::TypeConstraints 'find_type_constraint';

use Moose::Meta::TypeConstraint::Union;

my ( $item, $int, $classname, $num )
    = map { find_type_constraint($_) } qw{Item Int ClassName Num};

ok( $int->is_subtype_of($item),       'Int is subtype of Item' );
ok( $classname->is_subtype_of($item), 'ClassName is subtype of Item' );
ok(
    ( not $int->is_subtype_of($classname) ),
    'Int is not subtype of ClassName'
);
ok(
    ( not $classname->is_subtype_of($int) ),
    'ClassName is not subtype of Int'
);

my $union = Moose::Meta::TypeConstraint::Union->new(
    type_constraints => [ $int, $classname ] );

my @domain_values = qw( 85439 Moose::Meta::TypeConstraint );
is(
    exception { $union->assert_valid($_) },
    undef,
    qq{Union accepts "$_".}
) for @domain_values;

ok(
    $union->is_subtype_of( find_type_constraint($_) ),
    "Int|ClassName is a subtype of $_"
) for qw{Item Defined Value Str};

ok(
    ( not $union->is_subtype_of( find_type_constraint($_) ) ),
    "Int|ClassName is not a subtype of $_"
) for qw{Num Int ClassName};

ok(
    ( not $union->is_a_type_of( find_type_constraint($_) ) ),
    "Int|ClassName is not a type of $_"
) for qw{Int ClassName};
done_testing;
