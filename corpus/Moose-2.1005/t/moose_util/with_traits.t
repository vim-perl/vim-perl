#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::Moose;

use Moose ();
use Moose::Util qw(with_traits);

{
    package Foo;
    use Moose;
}

{
    package Foo::Role;
    use Moose::Role;
}

{
    package Foo::Role2;
    use Moose::Role;
}

{
    my $traited_class = with_traits('Foo', 'Foo::Role');
    ok($traited_class->meta->is_anon_class, "we get an anon class");
    isa_ok($traited_class, 'Foo');
    does_ok($traited_class, 'Foo::Role');
}

{
    my $traited_class = with_traits('Foo', 'Foo::Role', 'Foo::Role2');
    ok($traited_class->meta->is_anon_class, "we get an anon class");
    isa_ok($traited_class, 'Foo');
    does_ok($traited_class, 'Foo::Role');
    does_ok($traited_class, 'Foo::Role2');
}

{
    my $traited_class = with_traits('Foo');
    is($traited_class, 'Foo', "don't apply anything if we don't get any traits");
}

{
    my $traited_class = with_traits('Foo', 'Foo::Role');
    my $traited_class2 = with_traits('Foo', 'Foo::Role');
    is($traited_class, $traited_class2, "get the same class back when passing the same roles");
}

done_testing;
