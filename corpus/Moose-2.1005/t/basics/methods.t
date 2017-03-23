#!/usr/bin/perl

use strict;
use warnings;

use Test::More;


my $test1 = Moose::Meta::Class->create_anon_class;
$test1->add_method( 'foo1', sub { } );

my $t1    = $test1->new_object;
my $t1_am = $t1->meta->get_method('foo1')->associated_metaclass;

ok( $t1_am, 'associated_metaclass is defined' );

isa_ok(
    $t1_am, 'Moose::Meta::Class',
    'associated_metaclass is correct class'
);

like( $t1_am->name(), qr/::__ANON__::/,
    'associated_metaclass->name looks like an anonymous class' );

{
    package Test2;

    use Moose;

    sub foo2 { }
}

my $t2    = Test2->new;
my $t2_am = $t2->meta->get_method('foo2')->associated_metaclass;

ok( $t2_am, 'associated_metaclass is defined' );

isa_ok(
    $t2_am, 'Moose::Meta::Class',
    'associated_metaclass is correct class'
);

is( $t2_am->name(), 'Test2',
    'associated_metaclass->name is Test2' );

done_testing;
