#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;

use Moose::Meta::Role;
use Moose::Util::TypeConstraints ();

{
    package FooRole;

    our $VERSION = '0.01';

    sub foo { 'FooRole::foo' }
}

my $foo_role = Moose::Meta::Role->initialize('FooRole');
isa_ok($foo_role, 'Moose::Meta::Role');
isa_ok($foo_role, 'Class::MOP::Module');

is($foo_role->name, 'FooRole', '... got the right name of FooRole');
is($foo_role->version, '0.01', '... got the right version of FooRole');

# methods ...

ok($foo_role->has_method('foo'), '... FooRole has the foo method');
is($foo_role->get_method('foo')->body, \&FooRole::foo, '... FooRole got the foo method');

isa_ok($foo_role->get_method('foo'), 'Moose::Meta::Role::Method');

is_deeply(
    [ $foo_role->get_method_list() ],
    [ 'foo' ],
    '... got the right method list');

# attributes ...

is_deeply(
    [ $foo_role->get_attribute_list() ],
    [],
    '... got the right attribute list');

ok(!$foo_role->has_attribute('bar'), '... FooRole does not have the bar attribute');

is( exception {
    $foo_role->add_attribute('bar' => (is => 'rw', isa => 'Foo'));
}, undef, '... added the bar attribute okay' );

is_deeply(
    [ $foo_role->get_attribute_list() ],
    [ 'bar' ],
    '... got the right attribute list');

ok($foo_role->has_attribute('bar'), '... FooRole does have the bar attribute');

my $bar = $foo_role->get_attribute('bar');
is_deeply( $bar->original_options, { is => 'rw', isa => 'Foo' },
    'original options for bar attribute' );
my $bar_for_class = $bar->attribute_for_class('Moose::Meta::Attribute');
is(
    $bar_for_class->type_constraint,
    Moose::Util::TypeConstraints::class_type('Foo'),
    'bar has a Foo class type'
);

is( exception {
    $foo_role->add_attribute('baz' => (is => 'ro'));
}, undef, '... added the baz attribute okay' );

is_deeply(
    [ sort $foo_role->get_attribute_list() ],
    [ 'bar', 'baz' ],
    '... got the right attribute list');

ok($foo_role->has_attribute('baz'), '... FooRole does have the baz attribute');

my $baz = $foo_role->get_attribute('baz');
is_deeply( $baz->original_options, { is => 'ro' },
    'original options for baz attribute' );

is( exception {
    $foo_role->remove_attribute('bar');
}, undef, '... removed the bar attribute okay' );

is_deeply(
    [ $foo_role->get_attribute_list() ],
    [ 'baz' ],
    '... got the right attribute list');

ok(!$foo_role->has_attribute('bar'), '... FooRole does not have the bar attribute');
ok($foo_role->has_attribute('baz'), '... FooRole does still have the baz attribute');

# method modifiers

ok(!$foo_role->has_before_method_modifiers('boo'), '... no boo:before modifier');

my $method = sub { "FooRole::boo:before" };
is( exception {
    $foo_role->add_before_method_modifier('boo' => $method);
}, undef, '... added a method modifier okay' );

ok($foo_role->has_before_method_modifiers('boo'), '... now we have a boo:before modifier');
is(($foo_role->get_before_method_modifiers('boo'))[0], $method, '... got the right method back');

is_deeply(
    [ $foo_role->get_method_modifier_list('before') ],
    [ 'boo' ],
    '... got the right list of before method modifiers');

done_testing;
