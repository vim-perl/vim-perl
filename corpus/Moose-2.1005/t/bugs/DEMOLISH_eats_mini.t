#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;


{
    package Foo;
    use Moose;

    has 'bar' => (
        is       => 'ro',
        required => 1,
    );

    # Defining this causes the FIRST call to Baz->new w/o param to fail,
    # if no call to ANY Moose::Object->new was done before.
    sub DEMOLISH {
        my ( $self ) = @_;
        # ... Moose (kinda) eats exceptions in DESTROY/DEMOLISH";
    }
}

{
    my $obj = eval { Foo->new; };
    like( $@, qr/is required/, "... Foo plain" );
    is( $obj, undef, "... the object is undef" );
}

{
    package Bar;

    sub new { die "Bar died"; }

    sub DESTROY {
        die "Vanilla Perl eats exceptions in DESTROY too";
    }
}

{
    my $obj = eval { Bar->new; };
    like( $@, qr/Bar died/, "... Bar plain" );
    is( $obj, undef, "... the object is undef" );
}

{
    package Baz;
    use Moose;

    sub DEMOLISH {
        $? = 0;
    }
}

{
    local $@ = 42;
    local $? = 84;

    {
        Baz->new;
    }

    is( $@, 42, '$@ is still 42 after object is demolished without dying' );
    is( $?, 84, '$? is still 84 after object is demolished without dying' );

    local $@ = 0;

    {
        Baz->new;
    }

    is( $@, 0, '$@ is still 0 after object is demolished without dying' );

    Baz->meta->make_immutable, redo
        if Baz->meta->is_mutable
}

done_testing;
