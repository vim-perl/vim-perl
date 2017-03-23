#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;
use Scalar::Util qw(refaddr);

{
    package Foo;
    use Moose;

    has 'array' => (
        traits  => ['Array'],
        is      => 'ro',
        handles => { array_clone => 'shallow_clone' },
    );

    has 'hash' => (
        traits  => ['Hash'],
        is      => 'ro',
        handles => { hash_clone => 'shallow_clone' },
    );

    no Moose;
}

my $array = [ 1, 2, 3 ];
my $hash  = { a => 1, b => 2 };

my $obj = Foo->new({
  array => $array,
  hash  => $hash,
});

my $array_clone = $obj->array_clone;
my $hash_clone  = $obj->hash_clone;

isnt(refaddr($array), refaddr($array_clone), "array clone refers to new copy");
is_deeply($array_clone, $array, "...but contents are the same");
isnt(refaddr($hash),  refaddr($hash_clone),  "hash clone refers to new copy");
is_deeply($hash_clone, $hash, "...but contents are the same");

done_testing;
