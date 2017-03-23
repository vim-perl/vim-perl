#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;


{
    package Foo;
    use Moose;

    sub foo { 'Foo::foo(' . (inner() || '') . ')' }
    sub bar { 'Foo::bar(' . (inner() || '') . ')' }
    sub baz { 'Foo::baz(' . (inner() || '') . ')' }

    package Bar;
    use Moose;

    extends 'Foo';

    augment foo => sub { 'Bar::foo(' . (inner() || '') . ')' };
    augment bar => sub { 'Bar::bar' };

    no Moose; # ensure inner() still works after unimport

    package Baz;
    use Moose;

    extends 'Bar';

    augment foo => sub { 'Baz::foo' };
    augment baz => sub { 'Baz::baz' };

    # this will actually never run,
    # because Bar::bar does not call inner()
    augment bar => sub { 'Baz::bar' };
}

my $baz = Baz->new();
isa_ok($baz, 'Baz');
isa_ok($baz, 'Bar');
isa_ok($baz, 'Foo');

is($baz->foo(), 'Foo::foo(Bar::foo(Baz::foo))', '... got the right value from &foo');
is($baz->bar(), 'Foo::bar(Bar::bar)', '... got the right value from &bar');
is($baz->baz(), 'Foo::baz(Baz::baz)', '... got the right value from &baz');

my $bar = Bar->new();
isa_ok($bar, 'Bar');
isa_ok($bar, 'Foo');

is($bar->foo(), 'Foo::foo(Bar::foo())', '... got the right value from &foo');
is($bar->bar(), 'Foo::bar(Bar::bar)', '... got the right value from &bar');
is($bar->baz(), 'Foo::baz()', '... got the right value from &baz');

my $foo = Foo->new();
isa_ok($foo, 'Foo');

is($foo->foo(), 'Foo::foo()', '... got the right value from &foo');
is($foo->bar(), 'Foo::bar()', '... got the right value from &bar');
is($foo->baz(), 'Foo::baz()', '... got the right value from &baz');

# test saved state when crossing objects

{
    package X;
    use Moose;
    has name => (is => 'rw');
    sub run {
        "$_[0]->{name}.X", inner()
    }

    package Y;
    use Moose;
    extends 'X';
    augment 'run' => sub {
        "$_[0]->{name}.Y", ($_[1] ? $_[1]->() : ()), inner();
    };

    package Z;
    use Moose;
    extends 'Y';
    augment 'run' => sub {
        "$_[0]->{name}.Z"
    }
}

is('a.X a.Y b.X b.Y b.Z a.Z',
   do {
       my $a = Z->new(name => 'a');
       my $b = Z->new(name => 'b');
       join(' ', $a->run(sub { $b->run }))
   },
   'State is saved when cross-calling augmented methods on different objects');

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
        augment 'bling' => sub {};
    }, undef, '... cannot augment a method which has a local equivalent' );

}

done_testing;
