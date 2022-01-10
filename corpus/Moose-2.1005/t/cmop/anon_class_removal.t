#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use Class::MOP;

{
    my $class;
    {
        my $meta = Class::MOP::Class->create_anon_class(
            methods => {
                foo => sub { 'FOO' },
            },
        );

        $class = $meta->name;
        can_ok($class, 'foo');
        is($class->foo, 'FOO');
    }
    ok(!$class->can('foo'));
}

{
    my $class;
    {
        my $meta = Class::MOP::Class->create_anon_class(
            methods => {
                foo => sub { 'FOO' },
            },
        );

        $class = $meta->name;
        can_ok($class, 'foo');
        is($class->foo, 'FOO');
        Class::MOP::remove_metaclass_by_name($class);
    }
    ok(!$class->can('foo'));
}

done_testing;
