#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

{
    package Foo;
    use Moose;

    has bar => ( is => "rw" );
    has baz => ( is => "rw" );

    sub BUILDARGS {
        my ( $self, @args ) = @_;
        unshift @args, "bar" if @args % 2 == 1;
        return {@args};
    }

    package Bar;
    use Moose;

    extends qw(Foo);
}

foreach my $class (qw(Foo Bar)) {
    is( $class->new->bar, undef, "no args" );
    is( $class->new( bar => 42 )->bar, 42, "normal args" );
    is( $class->new( 37 )->bar, 37, "single arg" );
    {
        my $o = $class->new(bar => 42, baz => 47);
        is($o->bar, 42, '... got the right bar');
        is($o->baz, 47, '... got the right bar');
    }
    {
        my $o = $class->new(42, baz => 47);
        is($o->bar, 42, '... got the right bar');
        is($o->baz, 47, '... got the right bar');
    }
}

done_testing;
