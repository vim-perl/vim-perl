#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

{
    package FooTrait;
    use Moose::Role;
}
{
    package Foo;
    use Moose -traits => ['FooTrait'];
}

is(Class::MOP::class_of('Foo'), Foo->meta,
    "class_of and ->meta are the same on Foo");
my $meta = Foo->meta;
is(Class::MOP::class_of($meta), $meta->meta,
    "class_of and ->meta are the same on Foo's metaclass");
isa_ok(Class::MOP::class_of($meta), 'Moose::Meta::Class');
isa_ok($meta->meta, 'Moose::Meta::Class');
ok($meta->is_mutable, "class is mutable");
ok(Class::MOP::class_of($meta)->is_mutable, "metaclass is mutable");
ok($meta->meta->does_role('FooTrait'), "does the trait");
Foo->meta->make_immutable;
is(Class::MOP::class_of('Foo'), Foo->meta,
    "class_of and ->meta are the same on Foo (immutable)");
$meta = Foo->meta;
isa_ok($meta->meta, 'Moose::Meta::Class');
ok($meta->is_immutable, "class is immutable");
ok($meta->meta->is_immutable, "metaclass is immutable (immutable class)");
is(Class::MOP::class_of($meta), $meta->meta,
    "class_of and ->meta are the same on Foo's metaclass (immutable)");
isa_ok(Class::MOP::class_of($meta), 'Moose::Meta::Class');
ok($meta->meta->does_role('FooTrait'), "still does the trait after immutable");

done_testing;
