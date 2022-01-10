#!/usr/bin/perl
use strict;
use warnings;

use Test::More;
use Test::Fatal;

{
    package Bomb;
    use Moose::Role;

    sub fuse { }
    sub explode { }

    package Spouse;
    use Moose::Role;

    sub fuse { }
    sub explode { }

    package Caninish;
    use Moose::Role;

    sub bark { }

    package Treeve;
    use Moose::Role;

    sub bark { }
}

{
    package PracticalJoke;
    use Moose;

    ::like( ::exception {
        with 'Bomb', 'Spouse';
    }, qr/Due to method name conflicts in roles 'Bomb' and 'Spouse', the methods 'explode' and 'fuse' must be implemented or excluded by 'PracticalJoke'/ );

    ::like( ::exception {
        with (
            'Bomb', 'Spouse',
            'Caninish', 'Treeve',
        );
    }, qr/Due to a method name conflict in roles 'Caninish' and 'Treeve', the method 'bark' must be implemented or excluded by 'PracticalJoke'/ );
}

done_testing;
