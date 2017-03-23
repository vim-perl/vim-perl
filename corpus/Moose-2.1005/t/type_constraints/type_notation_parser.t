#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Moose::Util::TypeConstraints;

=pod

This is a good candidate for LectroTest
Volunteers welcome :)

=cut

## check the containers

ok(Moose::Util::TypeConstraints::_detect_parameterized_type_constraint($_),
   '... this correctly detected a container (' . $_ . ')')
    for (
    'ArrayRef[Foo]',
    'ArrayRef[Foo | Int]',
    'ArrayRef[ArrayRef[Int]]',
    'ArrayRef[ArrayRef[Int | Foo]]',
    'ArrayRef[ArrayRef[Int|Str]]',
);

ok(!Moose::Util::TypeConstraints::_detect_parameterized_type_constraint($_),
   '... this correctly detected a non-container (' . $_ . ')')
    for (
    'ArrayRef[]',
    'ArrayRef[Foo]Bar',
);

{
    my %split_tests = (
        'ArrayRef[Foo]'                 => [ 'ArrayRef', 'Foo' ],
        'ArrayRef[Foo | Int]'           => [ 'ArrayRef', 'Foo | Int' ],
        'ArrayRef[Foo|Int]'             => [ 'ArrayRef', 'Foo|Int' ],
        # these will get processed with recusion,
        # so we only need to detect it once
        'ArrayRef[ArrayRef[Int]]'       => [ 'ArrayRef', 'ArrayRef[Int]' ],
        'ArrayRef[ArrayRef[Int | Foo]]' => [ 'ArrayRef', 'ArrayRef[Int | Foo]' ],
        'ArrayRef[ArrayRef[Int|Str]]'   => [ 'ArrayRef', 'ArrayRef[Int|Str]' ],
    );

    is_deeply(
        [ Moose::Util::TypeConstraints::_parse_parameterized_type_constraint($_) ],
        $split_tests{$_},
        '... this correctly split the container (' . $_ . ')'
    ) for keys %split_tests;
}

## now for the unions

ok(Moose::Util::TypeConstraints::_detect_type_constraint_union($_),
   '... this correctly detected union (' . $_ . ')')
    for (
    'Int | Str',
    'Int|Str',
    'ArrayRef[Foo] | Int',
    'ArrayRef[Foo]|Int',
    'Int | ArrayRef[Foo]',
    'Int|ArrayRef[Foo]',
    'ArrayRef[Foo | Int] | Str',
    'ArrayRef[Foo|Int]|Str',
    'Str | ArrayRef[Foo | Int]',
    'Str|ArrayRef[Foo|Int]',
    'Some|Silly|Name|With|Pipes | Int',
    'Some|Silly|Name|With|Pipes|Int',
);

ok(!Moose::Util::TypeConstraints::_detect_type_constraint_union($_),
   '... this correctly detected a non-union (' . $_ . ')')
    for (
    'Int',
    'ArrayRef[Foo | Int]',
    'ArrayRef[Foo|Int]',
);

{
    my %split_tests = (
        'Int | Str'                        => [ 'Int', 'Str' ],
        'Int|Str'                          => [ 'Int', 'Str' ],
        'ArrayRef[Foo] | Int'              => [ 'ArrayRef[Foo]', 'Int' ],
        'ArrayRef[Foo]|Int'                => [ 'ArrayRef[Foo]', 'Int' ],
        'Int | ArrayRef[Foo]'              => [ 'Int', 'ArrayRef[Foo]' ],
        'Int|ArrayRef[Foo]'                => [ 'Int', 'ArrayRef[Foo]' ],
        'ArrayRef[Foo | Int] | Str'        => [ 'ArrayRef[Foo | Int]', 'Str' ],
        'ArrayRef[Foo|Int]|Str'            => [ 'ArrayRef[Foo|Int]', 'Str' ],
        'Str | ArrayRef[Foo | Int]'        => [ 'Str', 'ArrayRef[Foo | Int]' ],
        'Str|ArrayRef[Foo|Int]'            => [ 'Str', 'ArrayRef[Foo|Int]' ],
        'Some|Silly|Name|With|Pipes | Int' => [ 'Some', 'Silly', 'Name', 'With', 'Pipes', 'Int' ],
        'Some|Silly|Name|With|Pipes|Int'   => [ 'Some', 'Silly', 'Name', 'With', 'Pipes', 'Int' ],
    );

    is_deeply(
        [ Moose::Util::TypeConstraints::_parse_type_constraint_union($_) ],
        $split_tests{$_},
        '... this correctly split the union (' . $_ . ')'
    ) for keys %split_tests;
}

done_testing;
