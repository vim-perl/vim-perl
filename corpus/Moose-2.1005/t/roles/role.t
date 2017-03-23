#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;

=pod

NOTE:

Should we be testing here that the has & override
are injecting their methods correctly? In other
words, should 'has_method' return true for them?

=cut

{
    package FooRole;
    use Moose::Role;

    our $VERSION = '0.01';

    has 'bar' => (is => 'rw', isa => 'Foo');
    has 'baz' => (is => 'ro');

    sub foo { 'FooRole::foo' }
    sub boo { 'FooRole::boo' }

    before 'boo' => sub { "FooRole::boo:before" };

    after  'boo' => sub { "FooRole::boo:after1"  };
    after  'boo' => sub { "FooRole::boo:after2"  };

    around 'boo' => sub { "FooRole::boo:around" };

    override 'bling' => sub { "FooRole::bling:override" };
    override 'fling' => sub { "FooRole::fling:override" };

    ::isnt( ::exception { extends() }, undef, '... extends() is not supported' );
    ::isnt( ::exception { augment() }, undef, '... augment() is not supported' );
    ::isnt( ::exception { inner()   }, undef, '... inner() is not supported' );

    no Moose::Role;
}

my $foo_role = FooRole->meta;
isa_ok($foo_role, 'Moose::Meta::Role');
isa_ok($foo_role, 'Class::MOP::Module');

is($foo_role->name, 'FooRole', '... got the right name of FooRole');
is($foo_role->version, '0.01', '... got the right version of FooRole');

# methods ...

ok($foo_role->has_method('foo'), '... FooRole has the foo method');
is($foo_role->get_method('foo')->body, \&FooRole::foo, '... FooRole got the foo method');

isa_ok($foo_role->get_method('foo'), 'Moose::Meta::Role::Method');

ok($foo_role->has_method('boo'), '... FooRole has the boo method');
is($foo_role->get_method('boo')->body, \&FooRole::boo, '... FooRole got the boo method');

isa_ok($foo_role->get_method('boo'), 'Moose::Meta::Role::Method');

is_deeply(
    [ sort $foo_role->get_method_list() ],
    [ 'boo', 'foo', 'meta' ],
    '... got the right method list');

ok(FooRole->can('foo'), "locally defined methods are still there");
ok(!FooRole->can('has'), "sugar was unimported");

# attributes ...

is_deeply(
    [ sort $foo_role->get_attribute_list() ],
    [ 'bar', 'baz' ],
    '... got the right attribute list');

ok($foo_role->has_attribute('bar'), '... FooRole does have the bar attribute');

my $bar_attr = $foo_role->get_attribute('bar');
is($bar_attr->{is}, 'rw',
   'bar attribute is rw');
is($bar_attr->{isa}, 'Foo',
   'bar attribute isa Foo');
is(ref($bar_attr->{definition_context}), 'HASH',
   'bar\'s definition context is a hash');
is($bar_attr->{definition_context}->{package}, 'FooRole',
   'bar was defined in FooRole');

ok($foo_role->has_attribute('baz'), '... FooRole does have the baz attribute');

my $baz_attr = $foo_role->get_attribute('baz');
is($baz_attr->{is}, 'ro',
   'baz attribute is ro');
is(ref($baz_attr->{definition_context}), 'HASH',
   'bar\'s definition context is a hash');
is($baz_attr->{definition_context}->{package}, 'FooRole',
   'baz was defined in FooRole');

# method modifiers

ok($foo_role->has_before_method_modifiers('boo'), '... now we have a boo:before modifier');
is(($foo_role->get_before_method_modifiers('boo'))[0]->(),
    "FooRole::boo:before",
    '... got the right method back');

is_deeply(
    [ $foo_role->get_method_modifier_list('before') ],
    [ 'boo' ],
    '... got the right list of before method modifiers');

ok($foo_role->has_after_method_modifiers('boo'), '... now we have a boo:after modifier');
is(($foo_role->get_after_method_modifiers('boo'))[0]->(),
    "FooRole::boo:after1",
    '... got the right method back');
is(($foo_role->get_after_method_modifiers('boo'))[1]->(),
    "FooRole::boo:after2",
    '... got the right method back');

is_deeply(
    [ $foo_role->get_method_modifier_list('after') ],
    [ 'boo' ],
    '... got the right list of after method modifiers');

ok($foo_role->has_around_method_modifiers('boo'), '... now we have a boo:around modifier');
is(($foo_role->get_around_method_modifiers('boo'))[0]->(),
    "FooRole::boo:around",
    '... got the right method back');

is_deeply(
    [ $foo_role->get_method_modifier_list('around') ],
    [ 'boo' ],
    '... got the right list of around method modifiers');

## overrides

ok($foo_role->has_override_method_modifier('bling'), '... now we have a bling:override modifier');
is($foo_role->get_override_method_modifier('bling')->(),
    "FooRole::bling:override",
    '... got the right method back');

ok($foo_role->has_override_method_modifier('fling'), '... now we have a fling:override modifier');
is($foo_role->get_override_method_modifier('fling')->(),
    "FooRole::fling:override",
    '... got the right method back');

is_deeply(
    [ sort $foo_role->get_method_modifier_list('override') ],
    [ 'bling', 'fling' ],
    '... got the right list of override method modifiers');

done_testing;
