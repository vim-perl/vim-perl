#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;



{
    package HTTPHeader;
    use Moose;

    has 'array' => (is => 'ro');
    has 'hash'  => (is => 'ro');
}

{
    package Request;
    use Moose;
    use Moose::Util::TypeConstraints;

    subtype Header =>
        => as Object
        => where { $_->isa('HTTPHeader') };

    coerce Header
        => from ArrayRef
            => via { HTTPHeader->new(array => $_[0]) }
        => from HashRef
            => via { HTTPHeader->new(hash => $_[0]) };

    has 'headers'  => (
        is      => 'rw',
        isa     => 'Header',
        coerce  => 1,
        lazy    => 1,
        default => sub { [ 'content-type', 'text/html' ] }
    );
}

my $r = Request->new;
isa_ok($r, 'Request');

is( exception {
    $r->headers;
}, undef, '... this coerces and passes the type constraint even with lazy' );

done_testing;
