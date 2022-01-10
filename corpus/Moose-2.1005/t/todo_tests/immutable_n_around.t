#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

# if make_immutable is removed from the following code the tests pass

{
    package Foo;
    use Moose;

    has foo => ( is => "ro" );

    package Bar;
    use Moose;

    extends qw(Foo);

    around new => sub {
        my $next = shift;
        my ( $self, @args ) = @_;
        $self->$next( foo => 42 );
    };

    package Gorch;
    use Moose;

    extends qw(Bar);

    package Zoink;
    use Moose;

    extends qw(Gorch);

}

my @classes = qw(Foo Bar Gorch Zoink);

tests: {
    is( Foo->new->foo, undef, "base class (" . (Foo->meta->is_immutable ? "immutable" : "mutable") . ")" );
    is( Bar->new->foo, 42, "around new called on Bar->new (" . (Bar->meta->is_immutable ? "immutable" : "mutable") . ")"  );
    is( Gorch->new->foo, 42, "around new called on Gorch->new (" . (Gorch->meta->is_immutable ? "immutable" : "mutable") . ")"  );
    is( Zoink->new->foo, 42, "around new called Zoink->new (" . (Zoink->meta->is_immutable ? "immutable" : "mutable") . ")"  );

    if ( @classes ) {
        local $SIG{__WARN__} = sub {};
        ( shift @classes )->meta->make_immutable;
        redo tests;
    }
}

done_testing;
