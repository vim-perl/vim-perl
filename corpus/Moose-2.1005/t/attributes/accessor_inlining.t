#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

my $called;
{
    package Foo::Meta::Instance;
    use Moose::Role;

    sub is_inlinable { 0 }

    after get_slot_value => sub { $called++ };
}

{
    package Foo;
    use Moose;
    Moose::Util::MetaRole::apply_metaroles(
        for => __PACKAGE__,
        class_metaroles => {
            instance => ['Foo::Meta::Instance'],
        },
    );

    has foo => (is => 'ro');
}

my $foo = Foo->new(foo => 1);
is($foo->foo, 1, "got the right value");
is($called, 1, "reader was called");

done_testing;
