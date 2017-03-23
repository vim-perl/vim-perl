#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::Fatal;

use Moose::Util::TypeConstraints;

{
    package Foo;
    use Moose;

    has unknown_class => (
        is  => 'ro',
        isa => 'UnknownClass',
    );

    has unknown_role => (
        is   => 'ro',
        does => 'UnknownRole',
    );
}

{
    my $meta = Foo->meta;

    my $class_tc = $meta->get_attribute('unknown_class')->type_constraint;
    isa_ok($class_tc, 'Moose::Meta::TypeConstraint::Class');
    is($class_tc, find_type_constraint('UnknownClass'),
       "class type is registered");
    like(
        exception { subtype 'UnknownClass', as 'Str'; },
        qr/The type constraint 'UnknownClass' has already been created in Foo and cannot be created again in main/,
        "Can't redefine implicitly defined class types"
    );

    my $role_tc = $meta->get_attribute('unknown_role')->type_constraint;
    isa_ok($role_tc, 'Moose::Meta::TypeConstraint::Role');
    is($role_tc, find_type_constraint('UnknownRole'),
       "role type is registered");
    like(
        exception { subtype 'UnknownRole', as 'Str'; },
        qr/The type constraint 'UnknownRole' has already been created in Foo and cannot be created again in main/,
        "Can't redefine implicitly defined class types"
    );
}

done_testing;
