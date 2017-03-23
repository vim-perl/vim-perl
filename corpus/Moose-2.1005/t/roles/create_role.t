#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Moose ();

my $role = Moose::Meta::Role->create(
    'MyItem::Role::Equipment',
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

my $class = Moose::Meta::Class->create('MyItem::Armor::Helmet' =>
    roles => ['MyItem::Role::Equipment'],
);

my $visored = $class->new_object(is_worn => 0);
ok(!$visored->is_worn, "attribute, accessor was consumed");
$visored->is_worn(1);
ok($visored->is_worn, "accessor was consumed");
$visored->remove;
ok(!$visored->is_worn, "method was consumed");

ok(!$role->is_anon_role, "the role is not anonymous");

my $composed_role = Moose::Meta::Role->create(
    'MyItem::Role::Equipment2',
    roles => [ $role ],
);

ok($composed_role->does_role('MyItem::Role::Equipment2'), "Role composed into role");

done_testing;
