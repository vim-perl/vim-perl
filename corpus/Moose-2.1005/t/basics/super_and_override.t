#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;


{
    package Foo;
    use Moose;

    sub foo { 'Foo::foo' }
    sub bar { 'Foo::bar' }
    sub baz { 'Foo::baz' }

    package Bar;
    use Moose;

    extends 'Foo';

    override bar => sub { 'Bar::bar -> ' . super() };

    package Baz;
    use Moose;

    extends 'Bar';

    override bar => sub { 'Baz::bar -> ' . super() };
    override baz => sub { 'Baz::baz -> ' . super() };

    no Moose; # ensure super() still works after unimport
}

my $baz = Baz->new();
isa_ok($baz, 'Baz');
isa_ok($baz, 'Bar');
isa_ok($baz, 'Foo');

is($baz->foo(), 'Foo::foo', '... got the right value from &foo');
is($baz->bar(), 'Baz::bar -> Bar::bar -> Foo::bar', '... got the right value from &bar');
is($baz->baz(), 'Baz::baz -> Foo::baz', '... got the right value from &baz');

my $bar = Bar->new();
isa_ok($bar, 'Bar');
isa_ok($bar, 'Foo');

is($bar->foo(), 'Foo::foo', '... got the right value from &foo');
is($bar->bar(), 'Bar::bar -> Foo::bar', '... got the right value from &bar');
is($bar->baz(), 'Foo::baz', '... got the right value from &baz');

my $foo = Foo->new();
isa_ok($foo, 'Foo');

is($foo->foo(), 'Foo::foo', '... got the right value from &foo');
is($foo->bar(), 'Foo::bar', '... got the right value from &bar');
is($foo->baz(), 'Foo::baz', '... got the right value from &baz');

# some error cases

{
    package Bling;
    use Moose;

    sub bling { 'Bling::bling' }

    package Bling::Bling;
    use Moose;

    extends 'Bling';

    sub bling { 'Bling::bling' }

    ::isnt( ::exception {
        override 'bling' => sub {};
    }, undef, '... cannot override a method which has a local equivalent' );

}

done_testing;
