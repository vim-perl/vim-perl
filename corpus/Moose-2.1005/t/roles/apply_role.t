#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;

{
    package FooRole;
    use Moose::Role;

    our $VERSION = 23;

    has 'bar' => ( is => 'rw', isa => 'FooClass' );
    has 'baz' => ( is => 'ro' );

    sub goo {'FooRole::goo'}
    sub foo {'FooRole::foo'}

    override 'boo' => sub { 'FooRole::boo -> ' . super() };

    around 'blau' => sub {
        my $c = shift;
        'FooRole::blau -> ' . $c->();
    };
}

{
    package BarRole;
    use Moose::Role;
    sub woot {'BarRole::woot'}
}

{
    package BarClass;
    use Moose;

    sub boo {'BarClass::boo'}
    sub foo {'BarClass::foo'}    # << the role overrides this ...
}

{
    package FooClass;
    use Moose;

    extends 'BarClass';

    ::like( ::exception { with 'FooRole' => { -version => 42 } }, qr/FooRole version 42 required--this is only version 23/, 'applying role with unsatisfied version requirement' );

    ::is( ::exception { with 'FooRole' => { -version => 13 } }, undef, 'applying role with satisfied version requirement' );

    sub blau {'FooClass::blau'}    # << the role wraps this ...

    sub goo {'FooClass::goo'}      # << overrides the one from the role ...
}

{
    package FooBarClass;
    use Moose;

    extends 'FooClass';
    with 'FooRole', 'BarRole';
}

{
    package PlainJane;
    sub new { return bless {}, __PACKAGE__; }
}

my $foo_class_meta = FooClass->meta;
isa_ok( $foo_class_meta, 'Moose::Meta::Class' );

my $foobar_class_meta = FooBarClass->meta;
isa_ok( $foobar_class_meta, 'Moose::Meta::Class' );

isnt( exception {
    $foo_class_meta->does_role();
}, undef, '... does_role requires a role name' );

isnt( exception {
    $foo_class_meta->add_role();
}, undef, '... apply_role requires a role' );

isnt( exception {
    $foo_class_meta->add_role( bless( {} => 'Fail' ) );
}, undef, '... apply_role requires a role' );

ok( $foo_class_meta->does_role('FooRole'),
    '... the FooClass->meta does_role FooRole' );
ok( !$foo_class_meta->does_role('OtherRole'),
    '... the FooClass->meta !does_role OtherRole' );

ok( $foobar_class_meta->does_role('FooRole'),
    '... the FooBarClass->meta does_role FooRole' );
ok( $foobar_class_meta->does_role('BarRole'),
    '... the FooBarClass->meta does_role BarRole' );
ok( !$foobar_class_meta->does_role('OtherRole'),
    '... the FooBarClass->meta !does_role OtherRole' );

foreach my $method_name (qw(bar baz foo boo blau goo)) {
    ok( $foo_class_meta->has_method($method_name),
        '... FooClass has the method ' . $method_name );
    ok( $foobar_class_meta->has_method($method_name),
        '... FooBarClass has the method ' . $method_name );
}

ok( !$foo_class_meta->has_method('woot'),
    '... FooClass lacks the method woot' );
ok( $foobar_class_meta->has_method('woot'),
    '... FooBarClass has the method woot' );

foreach my $attr_name (qw(bar baz)) {
    ok( $foo_class_meta->has_attribute($attr_name),
        '... FooClass has the attribute ' . $attr_name );
    ok( $foobar_class_meta->has_attribute($attr_name),
        '... FooBarClass has the attribute ' . $attr_name );
}

can_ok( 'FooClass', 'does' );
ok( FooClass->does('FooRole'),    '... the FooClass does FooRole' );
ok( !FooClass->does('BarRole'),   '... the FooClass does not do BarRole' );
ok( !FooClass->does('OtherRole'), '... the FooClass does not do OtherRole' );

can_ok( 'FooBarClass', 'does' );
ok( FooBarClass->does('FooRole'), '... the FooClass does FooRole' );
ok( FooBarClass->does('BarRole'), '... the FooBarClass does FooBarRole' );
ok( !FooBarClass->does('OtherRole'),
    '... the FooBarClass does not do OtherRole' );

my $foo = FooClass->new();
isa_ok( $foo, 'FooClass' );

my $foobar = FooBarClass->new();
isa_ok( $foobar, 'FooBarClass' );

is( $foo->goo,    'FooClass::goo', '... got the right value of goo' );
is( $foobar->goo, 'FooRole::goo',  '... got the right value of goo' );

is( $foo->boo, 'FooRole::boo -> BarClass::boo',
    '... got the right value from ->boo' );
is( $foobar->boo, 'FooRole::boo -> FooRole::boo -> BarClass::boo',
    '... got the right value from ->boo (double wrapped)' );

is( $foo->blau, 'FooRole::blau -> FooClass::blau',
    '... got the right value from ->blau' );
is( $foobar->blau, 'FooRole::blau -> FooRole::blau -> FooClass::blau',
    '... got the right value from ->blau' );

foreach my $foo ( $foo, $foobar ) {
    can_ok( $foo, 'does' );
    ok( $foo->does('FooRole'), '... an instance of FooClass does FooRole' );
    ok( !$foo->does('OtherRole'),
        '... and instance of FooClass does not do OtherRole' );

    can_ok( $foobar, 'does' );
    ok( $foobar->does('FooRole'),
        '... an instance of FooBarClass does FooRole' );
    ok( $foobar->does('BarRole'),
        '... an instance of FooBarClass does BarRole' );
    ok( !$foobar->does('OtherRole'),
        '... and instance of FooBarClass does not do OtherRole' );

    for my $method (qw/bar baz foo boo goo blau/) {
        can_ok( $foo, $method );
    }

    is( $foo->foo, 'FooRole::foo', '... got the right value of foo' );

    ok( !defined( $foo->baz ), '... $foo->baz is undefined' );
    ok( !defined( $foo->bar ), '... $foo->bar is undefined' );

    isnt( exception {
        $foo->baz(1);
    }, undef, '... baz is a read-only accessor' );

    isnt( exception {
        $foo->bar(1);
    }, undef, '... bar is a read-write accessor with a type constraint' );

    my $foo2 = FooClass->new();
    isa_ok( $foo2, 'FooClass' );

    is( exception {
        $foo->bar($foo2);
    }, undef, '... bar is a read-write accessor with a type constraint' );

    is( $foo->bar, $foo2, '... got the right value for bar now' );
}

{
    {
        package MRole;
        use Moose::Role;
        sub meth { }
    }

    {
        package MRole2;
        use Moose::Role;
        sub meth2 { }
    }

    {
        use Moose::Meta::Class;
        use Moose::Object;
        use Moose::Util qw(apply_all_roles);

        my $class = Moose::Meta::Class->create( 'Class' => (
          superclasses => [ 'Moose::Object' ],
        ));

        apply_all_roles($class, MRole->meta, MRole2->meta);

        ok(Class->can('meth'), "can meth");
        ok(Class->can('meth2'), "can meth2");
    }
}

{
    ok(!Moose::Util::find_meta('PlainJane'), 'not initialized');
    Moose::Util::apply_all_roles('PlainJane', 'BarRole');
    ok(Moose::Util::find_meta('PlainJane'), 'initialized');
    ok(Moose::Util::find_meta('PlainJane')->does_role('BarRole'), 'does BarRole');
    my $pj = PlainJane->new();
    ok($pj->can('woot'), 'can woot');
}

done_testing;
