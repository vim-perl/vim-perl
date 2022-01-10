#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;


{
    package Thing::Meta::Attribute;
    use Moose;

    extends 'Moose::Meta::Attribute';
    around illegal_options_for_inheritance => sub {
        return (shift->(@_), qw/trigger/);
    };

    package Thing;
    use Moose;

    sub hello   { 'Hello World (from Thing)' }
    sub goodbye { 'Goodbye World (from Thing)' }

    package Foo;
    use Moose;
    use Moose::Util::TypeConstraints;

    subtype 'FooStr'
        => as 'Str'
        => where { /Foo/ };

    coerce 'FooStr'
        => from ArrayRef
            => via { 'FooArrayRef' };

    has 'bar' => (is => 'ro', isa => 'Str', default => 'Foo::bar');
    has 'baz' => (is => 'rw', isa => 'Ref');
    has 'foo' => (is => 'rw', isa => 'FooStr');

    has 'gorch' => (is => 'ro');
    has 'gloum' => (is => 'ro', default => sub {[]});
    has 'fleem' => (is => 'ro');

    has 'bling' => (is => 'ro', isa => 'Thing');
    has 'blang' => (is => 'ro', isa => 'Thing', handles => ['goodbye']);

    has 'bunch_of_stuff' => (is => 'rw', isa => 'ArrayRef');

    has 'one_last_one' => (is => 'rw', isa => 'Ref');

    # this one will work here ....
    has 'fail' => (isa => 'CodeRef', is => 'bare');
    has 'other_fail' => (metaclass => 'Thing::Meta::Attribute', is => 'bare', trigger => sub { });

    package Bar;
    use Moose;
    use Moose::Util::TypeConstraints;

    extends 'Foo';

    ::is( ::exception {
        has '+bar' => (default => 'Bar::bar');
    }, undef, '... we can change the default attribute option' );

    ::is( ::exception {
        has '+baz' => (isa => 'ArrayRef');
    }, undef, '... we can add change the isa as long as it is a subtype' );

    ::is( ::exception {
        has '+foo' => (coerce => 1);
    }, undef, '... we can change/add coerce as an attribute option' );

    ::is( ::exception {
        has '+gorch' => (required => 1);
    }, undef, '... we can change/add required as an attribute option' );

    ::is( ::exception {
        has '+gloum' => (lazy => 1);
    }, undef, '... we can change/add lazy as an attribute option' );

    ::is( ::exception {
        has '+fleem' => (lazy_build => 1);
    }, undef, '... we can add lazy_build as an attribute option' );

    ::is( ::exception {
        has '+bunch_of_stuff' => (isa => 'ArrayRef[Int]');
    }, undef, '... extend an attribute with parameterized type' );

    ::is( ::exception {
        has '+one_last_one' => (isa => subtype('Ref', where { blessed $_ eq 'CODE' }));
    }, undef, '... extend an attribute with anon-subtype' );

    ::is( ::exception {
        has '+one_last_one' => (isa => 'Value');
    }, undef, '... now can extend an attribute with a non-subtype' );

    ::is( ::exception {
        has '+fleem' => (weak_ref => 1);
    }, undef, '... now allowed to add the weak_ref option via inheritance' );

    ::is( ::exception {
        has '+bling' => (handles => ['hello']);
    }, undef, '... we can add the handles attribute option' );

    # this one will *not* work here ....
    ::isnt( ::exception {
        has '+blang' => (handles => ['hello']);
    }, undef, '... we can not alter the handles attribute option' );
    ::is( ::exception {
        has '+fail' => (isa => 'Ref');
    }, undef, '... can now create an attribute with an improper subtype relation' );
    ::isnt( ::exception {
        has '+other_fail' => (trigger => sub {});
    }, undef, '... cannot create an attribute with an illegal option' );
    ::like( ::exception {
        has '+does_not_exist' => (isa => 'Str');
    }, qr/in Bar/, '... cannot extend a non-existing attribute' );
}

my $foo = Foo->new;
isa_ok($foo, 'Foo');

is($foo->foo, undef, '... got the right undef default value');
is( exception { $foo->foo('FooString') }, undef, '... assigned foo correctly' );
is($foo->foo, 'FooString', '... got the right value for foo');

isnt( exception { $foo->foo([]) }, undef, '... foo is not coercing (as expected)' );

is($foo->bar, 'Foo::bar', '... got the right default value');
isnt( exception { $foo->bar(10) }, undef, '... Foo::bar is a read/only attr' );

is($foo->baz, undef, '... got the right undef default value');

{
    my $hash_ref = {};
    is( exception { $foo->baz($hash_ref) }, undef, '... Foo::baz accepts hash refs' );
    is($foo->baz, $hash_ref, '... got the right value assigned to baz');

    my $array_ref = [];
    is( exception { $foo->baz($array_ref) }, undef, '... Foo::baz accepts an array ref' );
    is($foo->baz, $array_ref, '... got the right value assigned to baz');

    my $scalar_ref = \(my $var);
    is( exception { $foo->baz($scalar_ref) }, undef, '... Foo::baz accepts scalar ref' );
    is($foo->baz, $scalar_ref, '... got the right value assigned to baz');

    is( exception { $foo->bunch_of_stuff([qw[one two three]]) }, undef, '... Foo::bunch_of_stuff accepts an array of strings' );

    is( exception { $foo->one_last_one(sub { 'Hello World'}) }, undef, '... Foo::one_last_one accepts a code ref' );

    my $code_ref = sub { 1 };
    is( exception { $foo->baz($code_ref) }, undef, '... Foo::baz accepts a code ref' );
    is($foo->baz, $code_ref, '... got the right value assigned to baz');
}

isnt( exception {
    Bar->new;
}, undef, '... cannot create Bar without required gorch param' );

my $bar = Bar->new(gorch => 'Bar::gorch');
isa_ok($bar, 'Bar');
isa_ok($bar, 'Foo');

is($bar->foo, undef, '... got the right undef default value');
is( exception { $bar->foo('FooString') }, undef, '... assigned foo correctly' );
is($bar->foo, 'FooString', '... got the right value for foo');
is( exception { $bar->foo([]) }, undef, '... assigned foo correctly' );
is($bar->foo, 'FooArrayRef', '... got the right value for foo');

is($bar->gorch, 'Bar::gorch', '... got the right default value');

is($bar->bar, 'Bar::bar', '... got the right default value');
isnt( exception { $bar->bar(10) }, undef, '... Bar::bar is a read/only attr' );

is($bar->baz, undef, '... got the right undef default value');

{
    my $hash_ref = {};
    isnt( exception { $bar->baz($hash_ref) }, undef, '... Bar::baz does not accept hash refs' );

    my $array_ref = [];
    is( exception { $bar->baz($array_ref) }, undef, '... Bar::baz can accept an array ref' );
    is($bar->baz, $array_ref, '... got the right value assigned to baz');

    my $scalar_ref = \(my $var);
    isnt( exception { $bar->baz($scalar_ref) }, undef, '... Bar::baz does not accept a scalar ref' );

    is( exception { $bar->bunch_of_stuff([1, 2, 3]) }, undef, '... Bar::bunch_of_stuff accepts an array of ints' );
    isnt( exception { $bar->bunch_of_stuff([qw[one two three]]) }, undef, '... Bar::bunch_of_stuff does not accept an array of strings' );

    my $code_ref = sub { 1 };
    isnt( exception { $bar->baz($code_ref) }, undef, '... Bar::baz does not accept a code ref' );
}

# check some meta-stuff

ok(Bar->meta->has_attribute('foo'), '... Bar has a foo attr');
ok(Bar->meta->has_attribute('bar'), '... Bar has a bar attr');
ok(Bar->meta->has_attribute('baz'), '... Bar has a baz attr');
ok(Bar->meta->has_attribute('gorch'), '... Bar has a gorch attr');
ok(Bar->meta->has_attribute('gloum'), '... Bar has a gloum attr');
ok(Bar->meta->has_attribute('bling'), '... Bar has a bling attr');
ok(Bar->meta->has_attribute('bunch_of_stuff'), '... Bar does have a bunch_of_stuff attr');
ok(!Bar->meta->has_attribute('blang'), '... Bar has a blang attr');
ok(Bar->meta->has_attribute('fail'), '... Bar has a fail attr');
ok(!Bar->meta->has_attribute('other_fail'), '... Bar does not have an other_fail attr');

isnt(Foo->meta->get_attribute('foo'),
     Bar->meta->get_attribute('foo'),
     '... Foo and Bar have different copies of foo');
isnt(Foo->meta->get_attribute('bar'),
     Bar->meta->get_attribute('bar'),
     '... Foo and Bar have different copies of bar');
isnt(Foo->meta->get_attribute('baz'),
     Bar->meta->get_attribute('baz'),
     '... Foo and Bar have different copies of baz');
isnt(Foo->meta->get_attribute('gorch'),
     Bar->meta->get_attribute('gorch'),
     '... Foo and Bar have different copies of gorch');
isnt(Foo->meta->get_attribute('gloum'),
     Bar->meta->get_attribute('gloum'),
     '... Foo and Bar have different copies of gloum');
isnt(Foo->meta->get_attribute('bling'),
     Bar->meta->get_attribute('bling'),
     '... Foo and Bar have different copies of bling');
isnt(Foo->meta->get_attribute('bunch_of_stuff'),
     Bar->meta->get_attribute('bunch_of_stuff'),
     '... Foo and Bar have different copies of bunch_of_stuff');

ok(Bar->meta->get_attribute('bar')->has_type_constraint,
   '... Bar::bar inherited the type constraint too');
ok(Bar->meta->get_attribute('baz')->has_type_constraint,
  '... Bar::baz inherited the type constraint too');

is(Bar->meta->get_attribute('bar')->type_constraint->name,
   'Str', '... Bar::bar inherited the right type constraint too');

is(Foo->meta->get_attribute('baz')->type_constraint->name,
  'Ref', '... Foo::baz inherited the right type constraint too');
is(Bar->meta->get_attribute('baz')->type_constraint->name,
   'ArrayRef', '... Bar::baz inherited the right type constraint too');

ok(!Foo->meta->get_attribute('gorch')->is_required,
  '... Foo::gorch is not a required attr');
ok(Bar->meta->get_attribute('gorch')->is_required,
   '... Bar::gorch is a required attr');

is(Foo->meta->get_attribute('bunch_of_stuff')->type_constraint->name,
  'ArrayRef',
  '... Foo::bunch_of_stuff is an ArrayRef');
is(Bar->meta->get_attribute('bunch_of_stuff')->type_constraint->name,
  'ArrayRef[Int]',
  '... Bar::bunch_of_stuff is an ArrayRef[Int]');

ok(!Foo->meta->get_attribute('gloum')->is_lazy,
   '... Foo::gloum is not a required attr');
ok(Bar->meta->get_attribute('gloum')->is_lazy,
   '... Bar::gloum is a required attr');

ok(!Foo->meta->get_attribute('foo')->should_coerce,
  '... Foo::foo should not coerce');
ok(Bar->meta->get_attribute('foo')->should_coerce,
   '... Bar::foo should coerce');

ok(!Foo->meta->get_attribute('bling')->has_handles,
   '... Foo::foo should not handles');
ok(Bar->meta->get_attribute('bling')->has_handles,
   '... Bar::foo should handles');

done_testing;
