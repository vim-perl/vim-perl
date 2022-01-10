#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;


{
    package My::Role;
    use Moose::Role;
}
{
    package My::Class;
    use Moose;

    ::like( ::exception {
        extends 'My::Role';
    }, qr/You cannot inherit from a Moose Role \(My\:\:Role\)/, '... this croaks correctly' );
}

done_testing;
