#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;

use Moose::Util::TypeConstraints;

# testing the parameterize method

{
    my $parameterizable = subtype 'parameterizable_hashref', as 'HashRef';

    my $parameterized = subtype 'parameterized_hashref', as 'HashRef[Int]';

    my $int = Moose::Util::TypeConstraints::find_type_constraint('Int');

    my $from_parameterizable = $parameterizable->parameterize($int);

    isa_ok $parameterizable,
        'Moose::Meta::TypeConstraint::Parameterizable', =>
        'Got expected type instance';

    package Test::Moose::Meta::TypeConstraint::Parameterizable;
    use Moose;

    has parameterizable      => ( is => 'rw', isa => $parameterizable );
    has parameterized        => ( is => 'rw', isa => $parameterized );
    has from_parameterizable => ( is => 'rw', isa => $from_parameterizable );
}

# Create and check a dummy object

ok my $params = Test::Moose::Meta::TypeConstraint::Parameterizable->new() =>
    'Create Dummy object for testing';

isa_ok $params, 'Test::Moose::Meta::TypeConstraint::Parameterizable' =>
    'isa correct type';

# test parameterizable

is( exception {
    $params->parameterizable( { a => 'Hello', b => 'World' } );
}, undef, 'No problem setting parameterizable' );

is_deeply $params->parameterizable,
    { a => 'Hello', b => 'World' } => 'Got expected values';

# test parameterized

is( exception {
    $params->parameterized( { a => 1, b => 2 } );
}, undef, 'No problem setting parameterized' );

is_deeply $params->parameterized, { a => 1, b => 2 } => 'Got expected values';

like( exception {
    $params->parameterized( { a => 'Hello', b => 'World' } );
    }, qr/Attribute \(parameterized\) does not pass the type constraint/, 'parameterized throws expected error' );

# test from_parameterizable

is( exception {
    $params->from_parameterizable( { a => 1, b => 2 } );
}, undef, 'No problem setting from_parameterizable' );

is_deeply $params->from_parameterizable,
    { a => 1, b => 2 } => 'Got expected values';

like( exception {
    $params->from_parameterizable( { a => 'Hello', b => 'World' } );
    }, qr/Attribute \(from_parameterizable\) does not pass the type constraint/, 'from_parameterizable throws expected error' );

done_testing;
