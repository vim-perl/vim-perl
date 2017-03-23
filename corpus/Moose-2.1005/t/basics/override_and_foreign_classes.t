#!/usr/bin/perl

use strict;
use warnings;

use Test::More;


=pod

This just tests the interaction of override/super
with non-Moose superclasses. It really should not
cause issues, the only thing it does is to create
a metaclass for Foo so that it can find the right
super method.

This may end up being a sensitive issue for some
non-Moose classes, but in 99% of the cases it
should be just fine.

=cut

{
    package Foo;
    use strict;
    use warnings;

    sub new { bless {} => shift() }

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

done_testing;
