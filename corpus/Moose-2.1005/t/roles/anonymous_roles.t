#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Moose ();

use Class::Load qw(is_class_loaded);

my $role = Moose::Meta::Role->create_anon_role(
    attributes => {
        is_worn => {
            is => 'rw',
            isa => 'Bool',
        },
    },
    methods => {
        remove => sub { shift->is_worn(0) },
    },
);

my $class = Moose::Meta::Class->create('MyItem::Armor::Helmet');
$role->apply($class);
# XXX: Moose::Util::apply_all_roles doesn't cope with references yet

my $visored = $class->new_object(is_worn => 0);
ok(!$visored->is_worn, "attribute, accessor was consumed");
$visored->is_worn(1);
ok($visored->is_worn, "accessor was consumed");
$visored->remove;
ok(!$visored->is_worn, "method was consumed");

like($role->name, qr/^Moose::Meta::Role::__ANON__::SERIAL::\d+$/, "");
ok($role->is_anon_role, "the role knows it's anonymous");

ok(is_class_loaded(Moose::Meta::Role->create_anon_role->name), "creating an anonymous role satisifes is_class_loaded");
ok(Class::MOP::class_of(Moose::Meta::Role->create_anon_role->name), "creating an anonymous role satisifes class_of");

{
    my $role;
    {
        my $meta = Moose::Meta::Role->create_anon_role(
            methods => {
                foo => sub { 'FOO' },
            },
        );

        $role = $meta->name;
        can_ok($role, 'foo');
    }
    ok(!$role->can('foo'));
}

{
    my $role;
    {
        my $meta = Moose::Meta::Role->create_anon_role(
            methods => {
                foo => sub { 'FOO' },
            },
        );

        $role = $meta->name;
        can_ok($role, 'foo');
        Class::MOP::remove_metaclass_by_name($role);
    }
    ok(!$role->can('foo'));
}

done_testing;
