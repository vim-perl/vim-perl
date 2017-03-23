#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::Fatal;

{
    use Moose::Util::TypeConstraints;
    use List::Util qw(sum);

    subtype 'A1', as 'ArrayRef[Int]';
    subtype 'A2', as 'ArrayRef', where { @$_ < 2 };
    subtype 'A3', as 'ArrayRef[Int]', where { ( sum(@$_) || 0 ) < 5 };

    subtype 'A5', as 'ArrayRef';
    coerce 'A5', from 'Str', via { [ $_ ] };

    no Moose::Util::TypeConstraints;
}

{
    package Foo;
    use Moose;

    has array => (
        traits  => ['Array'],
        is      => 'rw',
        isa     => 'ArrayRef',
        handles => {
            push_array => 'push',
        },
    );

    has array_int => (
        traits  => ['Array'],
        is      => 'rw',
        isa     => 'ArrayRef[Int]',
        handles => {
            push_array_int => 'push',
        },
    );

    has a1 => (
        traits  => ['Array'],
        is      => 'rw',
        isa     => 'A1',
        handles => {
            push_a1 => 'push',
        },
    );

    has a2 => (
        traits  => ['Array'],
        is      => 'rw',
        isa     => 'A2',
        handles => {
            push_a2 => 'push',
        },
    );

    has a3 => (
        traits  => ['Array'],
        is      => 'rw',
        isa     => 'A3',
        handles => {
            push_a3 => 'push',
        },
    );

    has a4 => (
        traits  => ['Array'],
        is      => 'rw',
        isa     => 'ArrayRef',
        lazy    => 1,
        default => 'invalid',
        clearer => '_clear_a4',
        handles => {
            get_a4      => 'get',
            push_a4     => 'push',
            accessor_a4 => 'accessor',
        },
    );

    has a5 => (
        traits  => ['Array'],
        is      => 'rw',
        isa     => 'A5',
        coerce  => 1,
        lazy    => 1,
        default => 'invalid',
        clearer => '_clear_a5',
        handles => {
            get_a5      => 'get',
            push_a5     => 'push',
            accessor_a5 => 'accessor',
        },
    );
}

my $foo = Foo->new;

{
    $foo->array( [] );
    is_deeply( $foo->array, [], "array - correct contents" );

    $foo->push_array('foo');
    is_deeply( $foo->array, ['foo'], "array - correct contents" );
}

{
    $foo->array_int( [] );
    is_deeply( $foo->array_int, [], "array_int - correct contents" );

    isnt( exception { $foo->push_array_int('foo') }, undef, "array_int - can't push wrong type" );
    is_deeply( $foo->array_int, [], "array_int - correct contents" );

    $foo->push_array_int(1);
    is_deeply( $foo->array_int, [1], "array_int - correct contents" );
}

{
    isnt( exception { $foo->push_a1('foo') }, undef, "a1 - can't push onto undef" );

    $foo->a1( [] );
    is_deeply( $foo->a1, [], "a1 - correct contents" );

    isnt( exception { $foo->push_a1('foo') }, undef, "a1 - can't push wrong type" );

    is_deeply( $foo->a1, [], "a1 - correct contents" );

    $foo->push_a1(1);
    is_deeply( $foo->a1, [1], "a1 - correct contents" );
}

{
    isnt( exception { $foo->push_a2('foo') }, undef, "a2 - can't push onto undef" );

    $foo->a2( [] );
    is_deeply( $foo->a2, [], "a2 - correct contents" );

    $foo->push_a2('foo');
    is_deeply( $foo->a2, ['foo'], "a2 - correct contents" );

    isnt( exception { $foo->push_a2('bar') }, undef, "a2 - can't push more than one element" );

    is_deeply( $foo->a2, ['foo'], "a2 - correct contents" );
}

{
    isnt( exception { $foo->push_a3(1) }, undef, "a3 - can't push onto undef" );

    $foo->a3( [] );
    is_deeply( $foo->a3, [], "a3 - correct contents" );

    isnt( exception { $foo->push_a3('foo') }, undef, "a3 - can't push non-int" );

    isnt( exception { $foo->push_a3(100) }, undef, "a3 - can't violate overall type constraint" );

    is_deeply( $foo->a3, [], "a3 - correct contents" );

    $foo->push_a3(1);
    is_deeply( $foo->a3, [1], "a3 - correct contents" );

    isnt( exception { $foo->push_a3(100) }, undef, "a3 - can't violate overall type constraint" );

    is_deeply( $foo->a3, [1], "a3 - correct contents" );

    $foo->push_a3(3);
    is_deeply( $foo->a3, [ 1, 3 ], "a3 - correct contents" );
}

{
    my $expect
        = qr/\QAttribute (a4) does not pass the type constraint because: Validation failed for 'ArrayRef' with value \E.*invalid.*/;

    like(
        exception { $foo->accessor_a4(0); },
        $expect,
        'invalid default is caught when trying to read via accessor'
    );

    like(
        exception { $foo->accessor_a4( 0 => 42 ); },
        $expect,
        'invalid default is caught when trying to write via accessor'
    );

    like(
        exception { $foo->push_a4(42); },
        $expect,
        'invalid default is caught when trying to push'
    );

    like(
        exception { $foo->get_a4(42); },
        $expect,
        'invalid default is caught when trying to get'
    );
}

{
    my $foo = Foo->new;

    is(
        $foo->accessor_a5(0), 'invalid',
        'lazy default is coerced when trying to read via accessor'
    );

    $foo->_clear_a5;

    $foo->accessor_a5( 1 => 'thing' );

    is_deeply(
        $foo->a5,
        [ 'invalid', 'thing' ],
        'lazy default is coerced when trying to write via accessor'
    );

    $foo->_clear_a5;

    $foo->push_a5('thing');

    is_deeply(
        $foo->a5,
        [ 'invalid', 'thing' ],
        'lazy default is coerced when trying to push'
    );

    $foo->_clear_a5;

    is(
        $foo->get_a5(0), 'invalid',
        'lazy default is coerced when trying to get'
    );
}

{
    package Bar;
    use Moose;
}

{
    package HasArray;
    use Moose;

    has objects => (
        isa     => 'ArrayRef[Foo]',
        traits  => ['Array'],
        handles => {
            push_objects => 'push',
        },
    );
}

{
    my $ha = HasArray->new();

    like(
        exception { $ha->push_objects( Bar->new ) },
        qr/\QValidation failed for 'Foo'/,
        'got expected error when pushing an object of the wrong class onto an array ref'
    );
}

done_testing;
