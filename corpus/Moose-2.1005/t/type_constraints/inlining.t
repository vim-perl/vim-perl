#!/usr/bin/perl

use strict;
use warnings;

use Test::Fatal;
use Test::More;

use Moose::Util::TypeConstraints;

#<<<
subtype 'Inlinable',
    as 'Str',
    where       { $_ !~ /Q/ },
    inline_as   { "defined $_[1] && ! ref $_[1] && $_[1] !~ /Q/" };

subtype 'NotInlinable',
    as 'Str',
    where { $_ !~ /Q/ };
#>>>

my $inlinable     = find_type_constraint('Inlinable');
my $not_inlinable = find_type_constraint('NotInlinable');

{
    ok(
        $inlinable->can_be_inlined,
        'Inlinable returns true for can_be_inlined'
    );

    is(
        $inlinable->_inline_check('$foo'),
        '( do { defined $foo && ! ref $foo && $foo !~ /Q/ } )',
        'got expected inline code for Inlinable constraint'
    );

    ok(
        !$not_inlinable->can_be_inlined,
        'NotInlinable returns false for can_be_inlined'
    );

    like(
        exception { $not_inlinable->_inline_check('$foo') },
        qr/Cannot inline a type constraint check for NotInlinable/,
        'threw an exception when asking for inlinable code from type which cannot be inlined'
    );
}

{
    my $aofi = Moose::Util::TypeConstraints::find_or_create_type_constraint(
        'ArrayRef[Inlinable]');

    ok(
        $aofi->can_be_inlined,
        'ArrayRef[Inlinable] returns true for can_be_inlined'
    );

    is(
        $aofi->_inline_check('$foo'),
        q{( do { do {my $check = $foo;ref($check) eq "ARRAY" && &List::MoreUtils::all(sub { ( do { defined $_ && ! ref $_ && $_ !~ /Q/ } ) }, @{$check})} } )},
        'got expected inline code for ArrayRef[Inlinable] constraint'
    );

    my $aofni = Moose::Util::TypeConstraints::find_or_create_type_constraint(
        'ArrayRef[NotInlinable]');

    ok(
        !$aofni->can_be_inlined,
        'ArrayRef[NotInlinable] returns false for can_be_inlined'
    );
}

subtype 'ArrayOfInlinable',
    as 'ArrayRef[Inlinable]';

subtype 'ArrayOfNotInlinable',
    as 'ArrayRef[NotInlinable]';
{
    my $aofi = Moose::Util::TypeConstraints::find_or_create_type_constraint(
        'ArrayOfInlinable');

    ok(
        $aofi->can_be_inlined,
        'ArrayOfInlinable returns true for can_be_inlined'
    );

    is(
        $aofi->_inline_check('$foo'),
        q{( do { do {my $check = $foo;ref($check) eq "ARRAY" && &List::MoreUtils::all(sub { ( do { defined $_ && ! ref $_ && $_ !~ /Q/ } ) }, @{$check})} } )},
        'got expected inline code for ArrayOfInlinable constraint'
    );

    my $aofni = Moose::Util::TypeConstraints::find_or_create_type_constraint(
        'ArrayOfNotInlinable');

    ok(
        !$aofni->can_be_inlined,
        'ArrayOfNotInlinable returns false for can_be_inlined'
    );
}

{
    my $hoaofi = Moose::Util::TypeConstraints::find_or_create_type_constraint(
        'HashRef[ArrayRef[Inlinable]]');

    ok(
        $hoaofi->can_be_inlined,
        'HashRef[ArrayRef[Inlinable]] returns true for can_be_inlined'
    );

    is(
        $hoaofi->_inline_check('$foo'),
        q{( do { do {my $check = $foo;ref($check) eq "HASH" && &List::MoreUtils::all(sub { ( do { do {my $check = $_;ref($check) eq "ARRAY" && &List::MoreUtils::all(sub { ( do { defined $_ && ! ref $_ && $_ !~ /Q/ } ) }, @{$check})} } ) }, values %{$check})} } )},
        'got expected inline code for HashRef[ArrayRef[Inlinable]] constraint'
    );

    my $hoaofni = Moose::Util::TypeConstraints::find_or_create_type_constraint(
        'HashRef[ArrayRef[NotInlinable]]');

    ok(
        !$hoaofni->can_be_inlined,
        'HashRef[ArrayRef[NotInlinable]] returns false for can_be_inlined'
    );
}

{
    my $iunion = Moose::Util::TypeConstraints::find_or_create_type_constraint(
        'Inlinable | Object');

    ok(
        $iunion->can_be_inlined,
        'Inlinable | Object returns true for can_be_inlined'
    );

    is(
        $iunion->_inline_check('$foo'),
        '((( do { defined $foo && ! ref $foo && $foo !~ /Q/ } )) || (( do { Scalar::Util::blessed($foo) } )))',
        'got expected inline code for Inlinable | Object constraint'
    );

    my $niunion = Moose::Util::TypeConstraints::find_or_create_type_constraint(
        'NotInlinable | Object');

    ok(
        !$niunion->can_be_inlined,
        'NotInlinable | Object returns false for can_be_inlined'
    );
}

{
    my $iunion = Moose::Util::TypeConstraints::find_or_create_type_constraint(
        'Object | Inlinable');

    ok(
        $iunion->can_be_inlined,
        'Object | Inlinable returns true for can_be_inlined'
    );

    is(
        $iunion->_inline_check('$foo'),
        '((( do { Scalar::Util::blessed($foo) } )) || (( do { defined $foo && ! ref $foo && $foo !~ /Q/ } )))',
        'got expected inline code for Object | Inlinable constraint'
    );

    my $niunion = Moose::Util::TypeConstraints::find_or_create_type_constraint(
        'Object | NotInlinable');

    ok(
        !$niunion->can_be_inlined,
        'Object | NotInlinable returns false for can_be_inlined'
    );
}

{
    my $iunion = Moose::Util::TypeConstraints::find_or_create_type_constraint(
        'Object | Inlinable | CodeRef');

    ok(
        $iunion->can_be_inlined,
        'Object | Inlinable | CodeRef returns true for can_be_inlined'
    );

    is(
        $iunion->_inline_check('$foo'),
        q{((( do { Scalar::Util::blessed($foo) } )) || (( do { defined $foo && ! ref $foo && $foo !~ /Q/ } )) || (( do { ref($foo) eq "CODE" } )))},
        'got expected inline code for Object | Inlinable | CodeRef constraint'
    );

    my $niunion = Moose::Util::TypeConstraints::find_or_create_type_constraint(
        'Object | NotInlinable | CodeRef');

    ok(
        !$niunion->can_be_inlined,
        'Object | NotInlinable | CodeRef returns false for can_be_inlined'
    );
}

done_testing;
