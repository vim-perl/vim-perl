#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;

use Scalar::Util 'isweak';


{
    package Foo;
    use Moose;

    eval {
        has 'foo' => (
            accessor => 'foo',
        );
    };
    ::ok(!$@, '... created the accessor method okay');

    eval {
        has 'lazy_foo' => (
            accessor => 'lazy_foo',
            lazy     => 1,
            default  => sub { 10 }
        );
    };
    ::ok(!$@, '... created the lazy accessor method okay');


    eval {
        has 'foo_required' => (
            accessor => 'foo_required',
            required => 1,
        );
    };
    ::ok(!$@, '... created the required accessor method okay');

    eval {
        has 'foo_int' => (
            accessor => 'foo_int',
            isa      => 'Int',
        );
    };
    ::ok(!$@, '... created the accessor method with type constraint okay');

    eval {
        has 'foo_weak' => (
            accessor => 'foo_weak',
            weak_ref => 1
        );
    };
    ::ok(!$@, '... created the accessor method with weak_ref okay');

    eval {
        has 'foo_deref' => (
            accessor => 'foo_deref',
            isa => 'ArrayRef',
            auto_deref => 1,
        );
    };
    ::ok(!$@, '... created the accessor method with auto_deref okay');

    eval {
        has 'foo_deref_ro' => (
            reader => 'foo_deref_ro',
            isa => 'ArrayRef',
            auto_deref => 1,
        );
    };
    ::ok(!$@, '... created the reader method with auto_deref okay');

    eval {
        has 'foo_deref_hash' => (
            accessor => 'foo_deref_hash',
            isa => 'HashRef',
            auto_deref => 1,
        );
    };
    ::ok(!$@, '... created the reader method with auto_deref okay');
}

{
    my $foo = Foo->new(foo_required => 'required');
    isa_ok($foo, 'Foo');

    # regular accessor

    can_ok($foo, 'foo');
    is($foo->foo(), undef, '... got an unset value');
    is( exception {
        $foo->foo(100);
    }, undef, '... foo wrote successfully' );
    is($foo->foo(), 100, '... got the correct set value');

    ok(!isweak($foo->{foo}), '... it is not a weak reference');

    # required writer

    isnt( exception {
        Foo->new;
    }, undef, '... cannot create without the required attribute' );

    can_ok($foo, 'foo_required');
    is($foo->foo_required(), 'required', '... got an unset value');
    is( exception {
        $foo->foo_required(100);
    }, undef, '... foo_required wrote successfully' );
    is($foo->foo_required(), 100, '... got the correct set value');

    is( exception {
        $foo->foo_required(undef);
    }, undef, '... foo_required did not die with undef' );

    is($foo->foo_required, undef, "value is undef");

    ok(!isweak($foo->{foo_required}), '... it is not a weak reference');

    # lazy

    ok(!exists($foo->{lazy_foo}), '... no value in lazy_foo slot');

    can_ok($foo, 'lazy_foo');
    is($foo->lazy_foo(), 10, '... got an deferred value');

    # with type constraint

    can_ok($foo, 'foo_int');
    is($foo->foo_int(), undef, '... got an unset value');
    is( exception {
        $foo->foo_int(100);
    }, undef, '... foo_int wrote successfully' );
    is($foo->foo_int(), 100, '... got the correct set value');

    isnt( exception {
        $foo->foo_int("Foo");
    }, undef, '... foo_int died successfully' );

    ok(!isweak($foo->{foo_int}), '... it is not a weak reference');

    # with weak_ref

    my $test = [];

    can_ok($foo, 'foo_weak');
    is($foo->foo_weak(), undef, '... got an unset value');
    is( exception {
        $foo->foo_weak($test);
    }, undef, '... foo_weak wrote successfully' );
    is($foo->foo_weak(), $test, '... got the correct set value');

    ok(isweak($foo->{foo_weak}), '... it is a weak reference');

    can_ok( $foo, 'foo_deref');
    is_deeply( [$foo->foo_deref()], [], '... default default value');
    my @list;
    is( exception {
        @list = $foo->foo_deref();
    }, undef, "... doesn't deref undef value" );
    is_deeply( \@list, [], "returns empty list in list context");

    is( exception {
        $foo->foo_deref( [ qw/foo bar gorch/ ] );
    }, undef, '... foo_deref wrote successfully' );

    is( Scalar::Util::reftype( scalar $foo->foo_deref() ), "ARRAY", "returns an array reference in scalar context" );
    is_deeply( scalar($foo->foo_deref()), [ qw/foo bar gorch/ ], "correct array" );

    is( scalar( () = $foo->foo_deref() ), 3, "returns list in list context" );
    is_deeply( [ $foo->foo_deref() ], [ qw/foo bar gorch/ ], "correct list" );


    can_ok( $foo, 'foo_deref' );
    is_deeply( [$foo->foo_deref_ro()], [], "... default default value" );

    isnt( exception {
        $foo->foo_deref_ro( [] );
    }, undef, "... read only" );

    $foo->{foo_deref_ro} = [qw/la la la/];

    is_deeply( scalar($foo->foo_deref_ro()), [qw/la la la/], "scalar context ro" );
    is_deeply( [ $foo->foo_deref_ro() ], [qw/la la la/], "list context ro" );

    can_ok( $foo, 'foo_deref_hash' );
    is_deeply( { $foo->foo_deref_hash() }, {}, "... default default value" );

    my %hash;
    is( exception {
        %hash = $foo->foo_deref_hash();
    }, undef, "... doesn't deref undef value" );
    is_deeply( \%hash, {}, "returns empty list in list context");

    is( exception {
        $foo->foo_deref_hash( { foo => 1, bar => 2 } );
    }, undef, '... foo_deref_hash wrote successfully' );

    is_deeply( scalar($foo->foo_deref_hash), { foo => 1, bar => 2 }, "scalar context" );

    %hash = $foo->foo_deref_hash;
    is_deeply( \%hash, { foo => 1, bar => 2 }, "list context");
}

done_testing;
