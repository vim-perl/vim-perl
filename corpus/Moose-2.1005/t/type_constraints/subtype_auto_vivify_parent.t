#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Moose::Util::TypeConstraints;


{
    package Foo;

    sub new {
        my $class = shift;

        return bless {@_}, $class;
    }
}

subtype 'FooWithSize'
    => as 'Foo'
    => where { $_[0]->{size} };


my $type = find_type_constraint('FooWithSize');
ok( $type,         'made a FooWithSize constraint' );
ok( $type->parent, 'type has a parent type' );
is( $type->parent->name, 'Foo', 'parent type is Foo' );
isa_ok( $type->parent, 'Moose::Meta::TypeConstraint::Class',
        'parent type constraint is a class type' );

done_testing;
