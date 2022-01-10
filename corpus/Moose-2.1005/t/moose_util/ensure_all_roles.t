#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Moose::Util ':all';

{
    package Foo;
    use Moose::Role;
}

{
    package Bar;
    use Moose::Role;
}

{
    package Quux;
    use Moose;
}

is_deeply(
    Quux->meta->roles,
    [],
    "no roles yet",
);

Foo->meta->apply(Quux->meta);

is_deeply(
    Quux->meta->roles,
    [ Foo->meta ],
    "applied Foo",
);

Foo->meta->apply(Quux->meta);
Bar->meta->apply(Quux->meta);
is_deeply(
    Quux->meta->roles,
    [ Foo->meta, Foo->meta, Bar->meta ],
    "duplicated Foo",
);

is(does_role('Quux', 'Foo'), 1, "Quux does Foo");
is(does_role('Quux', 'Bar'), 1, "Quux does Bar");
ensure_all_roles('Quux', qw(Foo Bar));
is_deeply(
    Quux->meta->roles,
    [ Foo->meta, Foo->meta, Bar->meta ],
    "unchanged, since all roles are already applied",
);

my $obj = Quux->new;
ensure_all_roles($obj, qw(Foo Bar));
is_deeply(
    $obj->meta->roles,
    [ Foo->meta, Foo->meta, Bar->meta ],
    "unchanged, since all roles are already applied",
);

done_testing;
