#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;

{
    use Moose::Util::TypeConstraints;
    use List::Util qw( sum );

    subtype 'H1', as 'HashRef[Int]';
    subtype 'H2', as 'HashRef', where { scalar keys %{$_} < 2 };
    subtype 'H3', as 'HashRef[Int]',
        where { ( sum( values %{$_} ) || 0 ) < 5 };

    subtype 'H5', as 'HashRef';
    coerce 'H5', from 'Str', via { { key => $_ } };

    no Moose::Util::TypeConstraints;
}

{

    package Foo;
    use Moose;

    has hash_int => (
        traits  => ['Hash'],
        is      => 'rw',
        isa     => 'HashRef[Int]',
        handles => {
            set_hash_int => 'set',
        },
    );

    has h1 => (
        traits  => ['Hash'],
        is      => 'rw',
        isa     => 'H1',
        handles => {
            set_h1 => 'set',
        },
    );

    has h2 => (
        traits  => ['Hash'],
        is      => 'rw',
        isa     => 'H2',
        handles => {
            set_h2 => 'set',
        },
    );

    has h3 => (
        traits  => ['Hash'],
        is      => 'rw',
        isa     => 'H3',
        handles => {
            set_h3 => 'set',
        },
    );

    has h4 => (
        traits  => ['Hash'],
        is      => 'rw',
        isa     => 'HashRef',
        lazy    => 1,
        default => 'invalid',
        clearer => '_clear_h4',
        handles => {
            get_h4      => 'get',
            accessor_h4 => 'accessor',
        },
    );

    has h5 => (
        traits  => ['Hash'],
        is      => 'rw',
        isa     => 'H5',
        coerce  => 1,
        lazy    => 1,
        default => 'invalid',
        clearer => '_clear_h5',
        handles => {
            get_h5      => 'get',
            accessor_h5 => 'accessor',
        },
    );
}

my $foo = Foo->new;

{
    $foo->hash_int( {} );
    is_deeply( $foo->hash_int, {}, "hash_int - correct contents" );

    isnt( exception { $foo->set_hash_int( x => 'foo' ) }, undef, "hash_int - can't set wrong type" );
    is_deeply( $foo->hash_int, {}, "hash_int - correct contents" );

    $foo->set_hash_int( x => 1 );
    is_deeply( $foo->hash_int, { x => 1 }, "hash_int - correct contents" );
}

{
    isnt( exception { $foo->set_h1('foo') }, undef, "h1 - can't set onto undef" );

    $foo->h1( {} );
    is_deeply( $foo->h1, {}, "h1 - correct contents" );

    isnt( exception { $foo->set_h1( x => 'foo' ) }, undef, "h1 - can't set wrong type" );

    is_deeply( $foo->h1, {}, "h1 - correct contents" );

    $foo->set_h1( x => 1 );
    is_deeply( $foo->h1, { x => 1 }, "h1 - correct contents" );
}

{
    isnt( exception { $foo->set_h2('foo') }, undef, "h2 - can't set onto undef" );

    $foo->h2( {} );
    is_deeply( $foo->h2, {}, "h2 - correct contents" );

    $foo->set_h2( x => 'foo' );
    is_deeply( $foo->h2, { x => 'foo' }, "h2 - correct contents" );

    isnt( exception { $foo->set_h2( y => 'bar' ) }, undef, "h2 - can't set more than one element" );

    is_deeply( $foo->h2, { x => 'foo' }, "h2 - correct contents" );
}

{
    isnt( exception { $foo->set_h3(1) }, undef, "h3 - can't set onto undef" );

    $foo->h3( {} );
    is_deeply( $foo->h3, {}, "h3 - correct contents" );

    isnt( exception { $foo->set_h3( x => 'foo' ) }, undef, "h3 - can't set non-int" );

    isnt( exception { $foo->set_h3( x => 100 ) }, undef, "h3 - can't violate overall type constraint" );

    is_deeply( $foo->h3, {}, "h3 - correct contents" );

    $foo->set_h3( x => 1 );
    is_deeply( $foo->h3, { x => 1 }, "h3 - correct contents" );

    isnt( exception { $foo->set_h3( x => 100 ) }, undef, "h3 - can't violate overall type constraint" );

    is_deeply( $foo->h3, { x => 1 }, "h3 - correct contents" );

    $foo->set_h3( y => 3 );
    is_deeply( $foo->h3, { x => 1, y => 3 }, "h3 - correct contents" );
}

{
    my $expect
        = qr/\QAttribute (h4) does not pass the type constraint because: Validation failed for 'HashRef' with value \E.*invalid.*/;

    like(
        exception { $foo->accessor_h4('key'); },
        $expect,
        'invalid default is caught when trying to read via accessor'
    );

    like(
        exception { $foo->accessor_h4( size => 42 ); },
        $expect,
        'invalid default is caught when trying to write via accessor'
    );

    like(
        exception { $foo->get_h4(42); },
        $expect,
        'invalid default is caught when trying to get'
    );
}

{
    my $foo = Foo->new;

    is(
        $foo->accessor_h5('key'), 'invalid',
        'lazy default is coerced when trying to read via accessor'
    );

    $foo->_clear_h5;

    $foo->accessor_h5( size => 42 );

    is_deeply(
        $foo->h5,
        { key => 'invalid', size => 42 },
        'lazy default is coerced when trying to write via accessor'
    );

    $foo->_clear_h5;

    is(
        $foo->get_h5('key'), 'invalid',
        'lazy default is coerced when trying to get'
    );
}

done_testing;
