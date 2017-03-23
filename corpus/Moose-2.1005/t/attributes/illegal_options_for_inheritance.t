#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
use Test::Fatal;

{
    package Foo;
    use Moose;

    has foo => (
        is => 'ro',
    );

    has bar => (
        clearer => 'clear_bar',
    );
}

{
    package Foo::Sub;
    use Moose;

    extends 'Foo';

    ::is( ::exception { has '+foo' => (is => 'rw') }, undef, "can override is" );
    ::like( ::exception { has '+foo' => (reader => 'bar') }, qr/illegal/, "can't override reader" );
    ::is( ::exception { has '+foo' => (clearer => 'baz') }, undef, "can override unspecified things" );

    ::like( ::exception { has '+bar' => (clearer => 'quux') }, qr/illegal/, "can't override clearer" );
    ::is( ::exception { has '+bar' => (predicate => 'has_bar') }, undef, "can override unspecified things" );
}

{
    package Bar::Meta::Attribute;
    use Moose::Role;

    has my_illegal_option => (is => 'ro');

    around illegal_options_for_inheritance => sub {
        return (shift->(@_), 'my_illegal_option');
    };
}

{
    package Bar;
    use Moose;

    ::is( ::exception {
        has bar => (
            traits            => ['Bar::Meta::Attribute'],
            my_illegal_option => 'FOO',
            is                => 'bare',
        );
    }, undef, "can use illegal options" );

    has baz => (
        traits => ['Bar::Meta::Attribute'],
        is     => 'bare',
    );
}

{
    package Bar::Sub;
    use Moose;

    extends 'Bar';

    ::like( ::exception { has '+bar' => (my_illegal_option => 'BAR') }, qr/illegal/, "can't override illegal attribute" );
    ::is( ::exception { has '+baz' => (my_illegal_option => 'BAR') }, undef, "can add illegal option if superclass doesn't set it" );
}

my $bar_attr = Bar->meta->get_attribute('bar');
ok((grep { $_ eq 'my_illegal_option' } $bar_attr->illegal_options_for_inheritance) > 0, '... added my_illegal_option as illegal option for inheritance');

done_testing;
