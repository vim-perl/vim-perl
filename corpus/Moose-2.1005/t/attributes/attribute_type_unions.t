#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;


{
    package Foo;
    use Moose;

    has 'bar' => (is => 'rw', isa => 'ArrayRef | HashRef');
}

my $foo = Foo->new;
isa_ok($foo, 'Foo');

is( exception {
    $foo->bar([])
}, undef, '... set bar successfully with an ARRAY ref' );

is( exception {
    $foo->bar({})
}, undef, '... set bar successfully with a HASH ref' );

isnt( exception {
    $foo->bar(100)
}, undef, '... couldnt set bar successfully with a number' );

isnt( exception {
    $foo->bar(sub {})
}, undef, '... couldnt set bar successfully with a CODE ref' );

# check the constructor

is( exception {
    Foo->new(bar => [])
}, undef, '... created new Foo with bar successfully set with an ARRAY ref' );

is( exception {
    Foo->new(bar => {})
}, undef, '... created new Foo with bar successfully set with a HASH ref' );

isnt( exception {
    Foo->new(bar => 50)
}, undef, '... didnt create a new Foo with bar as a number' );

isnt( exception {
    Foo->new(bar => sub {})
}, undef, '... didnt create a new Foo with bar as a CODE ref' );

{
    package Bar;
    use Moose;

    has 'baz' => (is => 'rw', isa => 'Str | CodeRef');
}

my $bar = Bar->new;
isa_ok($bar, 'Bar');

is( exception {
    $bar->baz('a string')
}, undef, '... set baz successfully with a string' );

is( exception {
    $bar->baz(sub { 'a sub' })
}, undef, '... set baz successfully with a CODE ref' );

isnt( exception {
    $bar->baz(\(my $var1))
}, undef, '... couldnt set baz successfully with a SCALAR ref' );

isnt( exception {
    $bar->baz({})
}, undef, '... couldnt set bar successfully with a HASH ref' );

# check the constructor

is( exception {
    Bar->new(baz => 'a string')
}, undef, '... created new Bar with baz successfully set with a string' );

is( exception {
    Bar->new(baz => sub { 'a sub' })
}, undef, '... created new Bar with baz successfully set with a CODE ref' );

isnt( exception {
    Bar->new(baz => \(my $var2))
}, undef, '... didnt create a new Bar with baz as a number' );

isnt( exception {
    Bar->new(baz => {})
}, undef, '... didnt create a new Bar with baz as a HASH ref' );

done_testing;
