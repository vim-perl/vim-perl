#!/usr/bin/perl

# this functionality may be pushing toward parametric roles/classes
# it's off in a corner and may not be that important

use strict;
use warnings;

use Test::More;
use Test::Fatal;

{
    package HasFoo;
    use Moose::Role;
    has 'foo' => (
        is       => 'ro',
        isa      => 'Str',
        required => 1,
    );

}

{
    package My::Metaclass;
    use Moose;
    extends 'Moose::Meta::Class';
    with 'HasFoo';
}

package main;

my $anon;
is( exception {
    $anon = My::Metaclass->create_anon_class( foo => 'this' );
}, undef, 'create anon class with required attr' );
isa_ok( $anon, 'My::Metaclass' );
cmp_ok( $anon->foo, 'eq', 'this', 'foo is this' );
isnt( exception {
    $anon = My::Metaclass->create_anon_class();
}, undef, 'failed to create anon class without required attr' );

my $meta;
is( exception {
    $meta
        = My::Metaclass->initialize( 'Class::Name1' => ( foo => 'that' ) );
}, undef, 'initialize a class with required attr' );
isa_ok( $meta, 'My::Metaclass' );
cmp_ok( $meta->foo,  'eq', 'that',        'foo is that' );
cmp_ok( $meta->name, 'eq', 'Class::Name1', 'for the correct class' );
isnt( exception {
    $meta
        = My::Metaclass->initialize( 'Class::Name2' );
}, undef, 'failed to initialize a class without required attr' );

is( exception {
    eval qq{
        package Class::Name3;
        use metaclass 'My::Metaclass' => (
            foo => 'another',
        );
        use Moose;
    };
    die $@ if $@;
}, undef, 'use metaclass with required attr' );
$meta = Class::Name3->meta;
isa_ok( $meta, 'My::Metaclass' );
cmp_ok( $meta->foo,  'eq', 'another',        'foo is another' );
cmp_ok( $meta->name, 'eq', 'Class::Name3', 'for the correct class' );
isnt( exception {
    eval qq{
        package Class::Name4;
        use metaclass 'My::Metaclass';
        use Moose;
    };
    die $@ if $@;
}, undef, 'failed to use metaclass without required attr' );


# how do we pass a required attribute to -traits?
isnt( exception {
    eval qq{
        package Class::Name5;
        use Moose -traits => 'HasFoo';
    };
    die $@ if $@;
}, undef, 'failed to use trait without required attr' );

done_testing;
