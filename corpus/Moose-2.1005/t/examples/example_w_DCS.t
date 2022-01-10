#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

=pod

This tests how well Moose type constraints
play with Declare::Constraints::Simple.

Pretty well if I do say so myself :)

=cut

use Test::Requires {
    'Declare::Constraints::Simple' => '0.01', # skip all if not installed
};

use Test::Fatal;

{
    package Foo;
    use Moose;
    use Moose::Util::TypeConstraints;
    use Declare::Constraints::Simple -All;

    # define your own type ...
    type( 'HashOfArrayOfObjects',
        {
        where => IsHashRef(
            -keys   => HasLength,
            -values => IsArrayRef(IsObject)
        )
    } );

    has 'bar' => (
        is  => 'rw',
        isa => 'HashOfArrayOfObjects',
    );

    # inline the constraints as anon-subtypes
    has 'baz' => (
        is  => 'rw',
        isa => subtype( { as => 'ArrayRef', where => IsArrayRef(IsInt) } ),
    );

    package Bar;
    use Moose;
}

my $hash_of_arrays_of_objs = {
   foo1 => [ Bar->new ],
   foo2 => [ Bar->new, Bar->new ],
};

my $array_of_ints = [ 1 .. 10 ];

my $foo;
is( exception {
    $foo = Foo->new(
       'bar' => $hash_of_arrays_of_objs,
       'baz' => $array_of_ints,
    );
}, undef, '... construction succeeded' );
isa_ok($foo, 'Foo');

is_deeply($foo->bar, $hash_of_arrays_of_objs, '... got our value correctly');
is_deeply($foo->baz, $array_of_ints, '... got our value correctly');

isnt( exception {
    $foo->bar([]);
}, undef, '... validation failed correctly' );

isnt( exception {
    $foo->bar({ foo => 3 });
}, undef, '... validation failed correctly' );

isnt( exception {
    $foo->bar({ foo => [ 1, 2, 3 ] });
}, undef, '... validation failed correctly' );

isnt( exception {
    $foo->baz([ "foo" ]);
}, undef, '... validation failed correctly' );

isnt( exception {
    $foo->baz({});
}, undef, '... validation failed correctly' );

done_testing;
