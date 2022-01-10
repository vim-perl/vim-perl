#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;


{
    package Foo;
    use Moose;

    has 'foo' => (
        reader => 'get_foo',
        writer => 'set_foo',
        initializer => sub {
            my ($self, $value, $callback, $attr) = @_;

            ::isa_ok($attr, 'Moose::Meta::Attribute');
            ::is($attr->name, 'foo', '... got the right name');

            $callback->($value * 2);
        },
    );

    has 'lazy_foo' => (
        reader      => 'get_lazy_foo',
        lazy        => 1,
        default     => 10,
        initializer => sub {
            my ($self, $value, $callback, $attr) = @_;

            ::isa_ok($attr, 'Moose::Meta::Attribute');
            ::is($attr->name, 'lazy_foo', '... got the right name');

            $callback->($value * 2);
        },
    );

    has 'lazy_foo_w_type' => (
        reader      => 'get_lazy_foo_w_type',
        isa         => 'Int',
        lazy        => 1,
        default     => 20,
        initializer => sub {
            my ($self, $value, $callback, $attr) = @_;

            ::isa_ok($attr, 'Moose::Meta::Attribute');
            ::is($attr->name, 'lazy_foo_w_type', '... got the right name');

            $callback->($value * 2);
        },
    );

    has 'lazy_foo_builder' => (
        reader      => 'get_lazy_foo_builder',
        builder     => 'get_foo_builder',
        initializer => sub {
            my ($self, $value, $callback, $attr) = @_;

            ::isa_ok($attr, 'Moose::Meta::Attribute');
            ::is($attr->name, 'lazy_foo_builder', '... got the right name');

            $callback->($value * 2);
        },
    );

    has 'lazy_foo_builder_w_type' => (
        reader      => 'get_lazy_foo_builder_w_type',
        isa         => 'Int',
        builder     => 'get_foo_builder_w_type',
        initializer => sub {
            my ($self, $value, $callback, $attr) = @_;

            ::isa_ok($attr, 'Moose::Meta::Attribute');
            ::is($attr->name, 'lazy_foo_builder_w_type', '... got the right name');

            $callback->($value * 2);
        },
    );

    sub get_foo_builder        { 100  }
    sub get_foo_builder_w_type { 1000 }
}

{
    my $foo = Foo->new(foo => 10);
    isa_ok($foo, 'Foo');

    is($foo->get_foo,             20, 'initial value set to 2x given value');
    is($foo->get_lazy_foo,        20, 'initial lazy value set to 2x given value');
    is($foo->get_lazy_foo_w_type, 40, 'initial lazy value with type set to 2x given value');
    is($foo->get_lazy_foo_builder,        200, 'initial lazy value with builder set to 2x given value');
    is($foo->get_lazy_foo_builder_w_type, 2000, 'initial lazy value with builder and type set to 2x given value');
}

{
    package Bar;
    use Moose;

    has 'foo' => (
        reader => 'get_foo',
        writer => 'set_foo',
        initializer => sub {
            my ($self, $value, $callback, $attr) = @_;

            ::isa_ok($attr, 'Moose::Meta::Attribute');
            ::is($attr->name, 'foo', '... got the right name');

            $callback->($value * 2);
        },
    );

    __PACKAGE__->meta->make_immutable;
}

{
    my $bar = Bar->new(foo => 10);
    isa_ok($bar, 'Bar');

    is($bar->get_foo, 20, 'initial value set to 2x given value');
}

{
    package Fail::Bar;
    use Moose;

    has 'foo' => (
        reader => 'get_foo',
        writer => 'set_foo',
        isa    => 'Int',
        initializer => sub {
            my ($self, $value, $callback, $attr) = @_;

            ::isa_ok($attr, 'Moose::Meta::Attribute');
            ::is($attr->name, 'foo', '... got the right name');

            $callback->("Hello $value World");
        },
    );

    __PACKAGE__->meta->make_immutable;
}

isnt( exception {
    Fail::Bar->new(foo => 10)
}, undef, '... this fails, because initializer returns a bad type' );

done_testing;
