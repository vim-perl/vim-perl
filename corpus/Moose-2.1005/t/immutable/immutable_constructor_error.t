#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;


=pod

This tests to make sure that we provide the same error messages from
an immutable constructor as is provided by a non-immutable
constructor.

=cut

{
    package Foo;
    use Moose;

    has 'foo' => (is => 'rw', isa => 'Int');

    Foo->meta->make_immutable(debug => 0);
}

my $scalar = 1;
like( exception { Foo->new($scalar) }, qr/\QSingle parameters to new() must be a HASH ref/, 'Non-ref provided to immutable constructor gives useful error message' );
like( exception { Foo->new(\$scalar) }, qr/\QSingle parameters to new() must be a HASH ref/, 'Scalar ref provided to immutable constructor gives useful error message' );
like( exception { Foo->new(undef) }, qr/\QSingle parameters to new() must be a HASH ref/, 'undef provided to immutable constructor gives useful error message' );

done_testing;
