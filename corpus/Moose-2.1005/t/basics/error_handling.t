#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;

# This tests the error handling in Moose::Object only

{
    package Foo;
    use Moose;
}

like( exception { Foo->new('bad') }, qr/^\QSingle parameters to new() must be a HASH ref/, 'A single non-hashref arg to a constructor throws an error' );
like( exception { Foo->new(undef) }, qr/^\QSingle parameters to new() must be a HASH ref/, 'A single non-hashref arg to a constructor throws an error' );

like( exception { Foo->does() }, qr/^\QYou must supply a role name to does()/, 'Cannot call does() without a role name' );

done_testing;
