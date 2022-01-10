#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;


{
    package My::Role;
    use Moose::Role;

    around 'baz' => sub {
        my $next = shift;
        'My::Role::baz(' . $next->(@_) . ')';
    };
}

{
    package Foo;
    use Moose;

    sub baz { 'Foo::baz' }

    __PACKAGE__->meta->make_immutable(debug => 0);
}

my $foo = Foo->new;
isa_ok($foo, 'Foo');

is($foo->baz, 'Foo::baz', '... got the right value');

is( exception {
    My::Role->meta->apply($foo)
}, undef, '... successfully applied the role to immutable instance' );

is($foo->baz, 'My::Role::baz(Foo::baz)', '... got the right value');

done_testing;
