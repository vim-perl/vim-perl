#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;


{
    {
        package Test::Attribute::Inline::Documentation;
        use Moose;

        has 'foo' => (
            documentation => q{
                The 'foo' attribute is my favorite
                attribute in the whole wide world.
            },
            is => 'bare',
        );
    }

    my $foo_attr = Test::Attribute::Inline::Documentation->meta->get_attribute('foo');

    ok($foo_attr->has_documentation, '... the foo has docs');
    is($foo_attr->documentation,
            q{
                The 'foo' attribute is my favorite
                attribute in the whole wide world.
            },
    '... got the foo docs');
}

{
    {
        package Test::For::Lazy::TypeConstraint;
        use Moose;
        use Moose::Util::TypeConstraints;

        has 'bad_lazy_attr' => (
            is => 'rw',
            isa => 'ArrayRef',
            lazy => 1,
            default => sub { "test" },
        );

        has 'good_lazy_attr' => (
            is => 'rw',
            isa => 'ArrayRef',
            lazy => 1,
            default => sub { [] },
        );

    }

    my $test = Test::For::Lazy::TypeConstraint->new;
    isa_ok($test, 'Test::For::Lazy::TypeConstraint');

    isnt( exception {
        $test->bad_lazy_attr;
    }, undef, '... this does not work' );

    is( exception {
        $test->good_lazy_attr;
    }, undef, '... this does not work' );
}

{
    {
        package Test::Arrayref::Attributes;
        use Moose;

        has [qw(foo bar baz)] => (
            is => 'rw',
        );

    }

    my $test = Test::Arrayref::Attributes->new;
    isa_ok($test, 'Test::Arrayref::Attributes');
    can_ok($test, qw(foo bar baz));

}

{
    {
        package Test::Arrayref::RoleAttributes::Role;
        use Moose::Role;

        has [qw(foo bar baz)] => (
            is => 'rw',
        );

    }
    {
        package Test::Arrayref::RoleAttributes;
        use Moose;
        with 'Test::Arrayref::RoleAttributes::Role';
    }

    my $test = Test::Arrayref::RoleAttributes->new;
    isa_ok($test, 'Test::Arrayref::RoleAttributes');
    can_ok($test, qw(foo bar baz));

}

{
    {
        package Test::UndefDefault::Attributes;
        use Moose;

        has 'foo' => (
            is      => 'ro',
            isa     => 'Str',
            default => sub { return }
        );

    }

    isnt( exception {
        Test::UndefDefault::Attributes->new;
    }, undef, '... default must return a value which passes the type constraint' );

}

{
    {
        package OverloadedStr;
        use Moose;
        use overload '""' => sub { 'this is *not* a string' };

        has 'a_str' => ( isa => 'Str' , is => 'rw' );
    }

    my $moose_obj = OverloadedStr->new;

    is($moose_obj->a_str( 'foobar' ), 'foobar', 'setter took string');
    ok($moose_obj, 'this is a *not* a string');

    like( exception {
        $moose_obj->a_str( $moose_obj )
    }, qr/Attribute \(a_str\) does not pass the type constraint because\: Validation failed for 'Str' with value .*OverloadedStr/, '... dies without overloading the string' );

}

{
    {
        package OverloadBreaker;
        use Moose;

        has 'a_num' => ( isa => 'Int' , is => 'rw', default => 7.5 );
    }

    like( exception {
        OverloadBreaker->new;
    }, qr/Attribute \(a_num\) does not pass the type constraint because\: Validation failed for 'Int' with value 7\.5/, '... this doesnt trip overload to break anymore ' );

    is( exception {
        OverloadBreaker->new(a_num => 5);
    }, undef, '... this works fine though' );

}

{
    {
      package Test::Builder::Attribute;
        use Moose;

        has 'foo'  => ( required => 1, builder => 'build_foo', is => 'ro');
        sub build_foo { return "works" };
    }

    my $meta = Test::Builder::Attribute->meta;
    my $foo_attr  = $meta->get_attribute("foo");

    ok($foo_attr->is_required, "foo is required");
    ok($foo_attr->has_builder, "foo has builder");
    is($foo_attr->builder, "build_foo",  ".. and it's named build_foo");

    my $instance = Test::Builder::Attribute->new;
    is($instance->foo, 'works', "foo builder works");
}

{
    {
        package Test::Builder::Attribute::Broken;
        use Moose;

        has 'foo'  => ( required => 1, builder => 'build_foo', is => 'ro');
    }

    isnt( exception {
        Test::Builder::Attribute::Broken->new;
    }, undef, '... no builder, wtf' );
}


{
    {
      package Test::LazyBuild::Attribute;
        use Moose;

        has 'foo'  => ( lazy_build => 1, is => 'ro');
        has '_foo' => ( lazy_build => 1, is => 'ro');
        has 'fool' => ( lazy_build => 1, is => 'ro');
        sub _build_foo { return "works" };
        sub _build__foo { return "works too" };
    }

    my $meta = Test::LazyBuild::Attribute->meta;
    my $foo_attr  = $meta->get_attribute("foo");
    my $_foo_attr = $meta->get_attribute("_foo");

    ok($foo_attr->is_lazy, "foo is lazy");
    ok($foo_attr->is_lazy_build, "foo is lazy_build");

    ok($foo_attr->has_clearer, "foo has clearer");
    is($foo_attr->clearer, "clear_foo",  ".. and it's named clear_foo");

    ok($foo_attr->has_builder, "foo has builder");
    is($foo_attr->builder, "_build_foo",  ".. and it's named build_foo");

    ok($foo_attr->has_predicate, "foo has predicate");
    is($foo_attr->predicate, "has_foo",  ".. and it's named has_foo");

    ok($_foo_attr->is_lazy, "_foo is lazy");
    ok(!$_foo_attr->is_required, "lazy_build attributes are no longer automatically required");
    ok($_foo_attr->is_lazy_build, "_foo is lazy_build");

    ok($_foo_attr->has_clearer, "_foo has clearer");
    is($_foo_attr->clearer, "_clear_foo",  ".. and it's named _clear_foo");

    ok($_foo_attr->has_builder, "_foo has builder");
    is($_foo_attr->builder, "_build__foo",  ".. and it's named _build_foo");

    ok($_foo_attr->has_predicate, "_foo has predicate");
    is($_foo_attr->predicate, "_has_foo",  ".. and it's named _has_foo");

    my $instance = Test::LazyBuild::Attribute->new;
    ok(!$instance->has_foo, "noo foo value yet");
    ok(!$instance->_has_foo, "noo _foo value yet");
    is($instance->foo, 'works', "foo builder works");
    is($instance->_foo, 'works too', "foo builder works too");
    like( exception { $instance->fool }, qr/Test::LazyBuild::Attribute does not support builder method \'_build_fool\' for attribute \'fool\'/, "Correct error when a builder method is not present" );

}

{
    package OutOfClassTest;

    use Moose;
}

is( exception { OutOfClassTest::has('foo', is => 'bare'); }, undef, 'create attr via direct sub call' );
is( exception { OutOfClassTest->can('has')->('bar', is => 'bare'); }, undef, 'create attr via can' );

ok(OutOfClassTest->meta->get_attribute('foo'), 'attr created from sub call');
ok(OutOfClassTest->meta->get_attribute('bar'), 'attr created from can');


{
    {
        package Foo;
        use Moose;

        ::like( ::exception { has 'foo' => ( 'ro', isa => 'Str' ) }, qr/^Usage/, 'has throws error with odd number of attribute options' );
    }

}

done_testing;
