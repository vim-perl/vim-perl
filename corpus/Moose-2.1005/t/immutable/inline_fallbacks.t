use strict;
use warnings;
use Test::More;

{
    package Foo;
    use Moose;
    has foo => (is => 'ro');
}

{
    package Foo::Sub;
    use Moose;
    extends 'Foo';
    has bar => (is => 'ro');
}

{
    my $foo = Foo::Sub->new(foo => 12, bar => 25);
    is($foo->foo, 12, 'got right value for foo');
    is($foo->bar, 25, 'got right value for bar');
}

Foo->meta->make_immutable;

{
    package Foo::Sub2;
    use Moose;
    extends 'Foo';
    has baz => (is => 'ro');
    # not making immutable, inheriting Foo's inlined constructor
}

{
    my $foo = Foo::Sub2->new(foo => 42, baz => 27);
    is($foo->foo, 42, 'got right value for foo');
    is($foo->baz, 27, 'got right value for baz');
}

my $BAR = 0;
{
    package Bar;
    use Moose;
}

{
    package Bar::Sub;
    use Moose;
    extends 'Bar';
    sub DEMOLISH { $BAR++ }
}

Bar::Sub->new;
is($BAR, 1, 'DEMOLISH in subclass was called');
$BAR = 0;

Bar->meta->make_immutable;

{
    package Bar::Sub2;
    use Moose;
    extends 'Bar';
    sub DEMOLISH { $BAR++ }
    # not making immutable, inheriting Bar's inlined destructor
}

Bar::Sub2->new;
is($BAR, 1, 'DEMOLISH in subclass was called');

done_testing;
