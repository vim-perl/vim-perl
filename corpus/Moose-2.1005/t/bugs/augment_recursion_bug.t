#!/usr/bin/perl

use strict;
use warnings;

use Test::More;


{
    package Foo;
    use Moose;

    sub foo { 'Foo::foo(' . (inner() || '') . ')' };

    package Bar;
    use Moose;

    extends 'Foo';

    package Baz;
    use Moose;

    extends 'Foo';

    my $foo_call_counter;
    augment 'foo' => sub {
        die "infinite loop on Baz::foo" if $foo_call_counter++ > 1;
        return 'Baz::foo and ' . Bar->new->foo;
    };
}

my $baz = Baz->new();
isa_ok($baz, 'Baz');
isa_ok($baz, 'Foo');

=pod

When a subclass which augments foo(), calls a subclass which does not augment
foo(), there is a chance for some confusion. If Moose does not realize that
Bar does not augment foo(), because it is in the call flow of Baz which does,
then we may have an infinite loop.

=cut

is($baz->foo,
  'Foo::foo(Baz::foo and Foo::foo())',
  '... got the right value for 1 augmented subclass calling non-augmented subclass');

done_testing;
