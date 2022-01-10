use strict;
use warnings;

use Class::MOP;

use Test::More;

{
    package Foo;
    use metaclass;

    Foo->meta->add_attribute( '@foo', accessor => 'foo' );
    Foo->meta->add_attribute( '!bar', reader => 'bar' );
    Foo->meta->add_attribute( '%baz', reader => 'baz' );
}

{
    my $meta = Foo->meta;

    for my $name ( '@foo', '!bar', '%baz' ) {
        ok(
            $meta->has_attribute($name),
            "Foo has $name attribute"
        );

        my $meth = substr $name, 1;
        ok( $meta->has_method($meth), 'Foo has $meth method' );
    }

    $meta->make_immutable, redo
        unless $meta->is_immutable;
}

done_testing;
