#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;

use Class::Load 'is_class_loaded';

{
    package Class;
    use Moose;

    package Foo;
    use Moose::Role;
    sub foo_role_applied { 1 }

    package Conflicts::With::Foo;
    use Moose::Role;
    sub foo_role_applied { 0 }

    package Not::A::Role;
    sub lol_wut { 42 }
}

my $new_class;

is( exception {
    $new_class = Moose::Meta::Class->create(
        'Class::WithFoo',
        superclasses => ['Class'],
        roles        => ['Foo'],
    );
}, undef, 'creating lives' );
ok $new_class;

my $with_foo = Class::WithFoo->new;

ok $with_foo->foo_role_applied;
isa_ok $with_foo, 'Class', '$with_foo';

like( exception {
    Moose::Meta::Class->create(
        'Made::Of::Fail',
        superclasses => ['Class'],
        roles => 'Foo', # "oops"
    );
}, qr/You must pass an ARRAY ref of roles/ );

ok !is_class_loaded('Made::Of::Fail'), "did not create Made::Of::Fail";

isnt( exception {
    Moose::Meta::Class->create(
        'Continuing::To::Fail',
        superclasses => ['Class'],
        roles        => ['Foo', 'Conflicts::With::Foo'],
    );
}, undef, 'conflicting roles == death' );

# XXX: Continuing::To::Fail gets created anyway

done_testing;
