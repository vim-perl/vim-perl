#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;
use Scalar::Util 'blessed';


{
    package Dog;
    use Moose::Role;

    sub talk { 'woof' }

    has fur => (
        isa => "Str",
        is  => "rw",
        default => "dirty",
    );

    package Foo;
    use Moose;

    has 'dog' => (
        is   => 'rw',
        does => 'Dog',
    );
}

my $obj = Foo->new;
isa_ok($obj, 'Foo');

ok(!$obj->can( 'talk' ), "... the role is not composed yet");
ok(!$obj->can( 'fur' ), 'ditto');
ok(!$obj->does('Dog'), '... we do not do any roles yet');

isnt( exception {
    $obj->dog($obj)
}, undef, '... and setting the accessor fails (not a Dog yet)' );

Dog->meta->apply($obj);

ok($obj->does('Dog'), '... we now do the Bark role');
ok($obj->can('talk'), "... the role is now composed at the object level");
ok($obj->can('fur'), "it has fur");

is($obj->talk, 'woof', '... got the right return value for the newly composed method');

is( exception {
    $obj->dog($obj)
}, undef, '... and setting the accessor is okay' );

is($obj->fur, "dirty", "role attr initialized");

done_testing;
