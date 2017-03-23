#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use Test::Fatal;

{
    package MyRole1;
    use Moose::Role;

    sub a_role_method { 'foo' }
}

{
    package MyRole2;
    use Moose::Role;
    # empty
}

{
    package Foo;
    use Moose;
}

my $instance_with_role1 = Foo->new;
MyRole1->meta->apply($instance_with_role1);

my $instance_with_role2 = Foo->new;
MyRole2->meta->apply($instance_with_role2);

ok ((not $instance_with_role2->does('MyRole1')),
    'instance does not have the wrong role');

ok ((not $instance_with_role2->can('a_role_method')),
    'instance does not have methods from the wrong role');

ok (($instance_with_role1->does('MyRole1')),
    'role was applied to the correct instance');

is( exception {
    is $instance_with_role1->a_role_method, 'foo'
}, undef, 'instance has correct role method' );

done_testing;
