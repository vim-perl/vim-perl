use strict;
use warnings;

use Test::More;

use Moose ();
use Moose::Meta::Role;
use Moose::Util;

my $role1 = Moose::Meta::Role->initialize('Foo');
$role1->add_attribute( foo => ( is => 'ro' ) );

ok( $role1->has_attribute('foo'), 'Foo role has a foo attribute' );

my $foo_attr = $role1->get_attribute('foo');
is(
    $foo_attr->associated_role->name, 'Foo',
    'associated_role for foo attr is Foo role'
);

isa_ok(
    $foo_attr->attribute_for_class('Moose::Meta::Attribute'),
    'Moose::Meta::Attribute',
    'attribute returned by ->attribute_for_class'
);

my $role2 = Moose::Meta::Role->initialize('Bar');
$role1->apply($role2);

ok( $role2->has_attribute('foo'), 'Bar role has a foo attribute' );

is(
    $foo_attr->associated_role->name, 'Foo',
    'associated_role for foo attr is still Foo role'
);

isa_ok(
    $foo_attr->attribute_for_class('Moose::Meta::Attribute'),
    'Moose::Meta::Attribute',
    'attribute returned by ->attribute_for_class'
);

my $role3 = Moose::Meta::Role->initialize('Baz');
my $combined = Moose::Meta::Role->combine( [ $role1->name ], [ $role3->name ] );

ok( $combined->has_attribute('foo'), 'combined role has a foo attribute' );

is(
    $foo_attr->associated_role->name, 'Foo',
    'associated_role for foo attr is still Foo role'
);

done_testing;
