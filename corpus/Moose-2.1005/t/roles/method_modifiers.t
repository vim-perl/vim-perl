#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::Fatal;

my $FooRole;
{
    package Foo::Role;
    use Moose::Role;
    after foo => sub { $FooRole++ };
}

{
    package Foo;
    use Moose;
    with 'Foo::Role';
    sub foo { }
}

Foo->foo;
is($FooRole, 1, "modifier called");

my $BarRole;
{
    package Bar::Role;
    use Moose::Role;
    after ['foo', 'bar'] => sub { $BarRole++ };
}

{
    package Bar;
    use Moose;
    with 'Bar::Role';
    sub foo { }
    sub bar { }
}

Bar->foo;
is($BarRole, 1, "modifier called");
Bar->bar;
is($BarRole, 2, "modifier called");

my $BazRole;
{
    package Baz::Role;
    use Moose::Role;
    after 'foo', 'bar' => sub { $BazRole++ };
}

{
    package Baz;
    use Moose;
    with 'Baz::Role';
    sub foo { }
    sub bar { }
}

Baz->foo;
is($BazRole, 1, "modifier called");
Baz->bar;
is($BazRole, 2, "modifier called");

my $QuuxRole;
{
    package Quux::Role;
    use Moose::Role;
    { our $TODO; local $TODO = "can't handle regexes yet";
    ::is( ::exception {
        after qr/foo|bar/ => sub { $QuuxRole++ }
    }, undef );
    }
}

{
    package Quux;
    use Moose;
    with 'Quux::Role';
    sub foo { }
    sub bar { }
}

{ local $TODO = "can't handle regexes yet";
Quux->foo;
is($QuuxRole, 1, "modifier called");
Quux->bar;
is($QuuxRole, 2, "modifier called");
}

done_testing;
