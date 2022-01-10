use strict;
use warnings;
use Test::More;
use Test::Fatal;

use Class::MOP;

=pod

This tests a bug sent via RT #39001

=cut

{
    package Foo;
    use metaclass;
}

like( exception {
    Foo->meta->superclasses('Foo');
}, qr/^Recursive inheritance detected/, "error occurs when extending oneself" );

{
    package Bar;
    use metaclass;
}

# reset @ISA, so that calling methods like ->isa won't die (->meta does this
# if DEBUG_NO_META is set)
@Foo::ISA = ();

is( exception {
    Foo->meta->superclasses('Bar');
}, undef, "regular subclass" );

like( exception {
    Bar->meta->superclasses('Foo');
}, qr/^Recursive inheritance detected/, "error occurs when Bar extends Foo, when Foo is a Bar" );

done_testing;
