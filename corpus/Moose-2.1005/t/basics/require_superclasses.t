#!/usr/bin/perl

use strict;
use warnings;

use lib 't/lib', 'lib';

use Test::More;
use Test::Fatal;


{

    package Bar;
    use Moose;

    ::is( ::exception { extends 'Foo' }, undef, 'loaded Foo superclass correctly' );
}

{

    package Baz;
    use Moose;

    ::is( ::exception { extends 'Bar' }, undef, 'loaded (inline) Bar superclass correctly' );
}

{

    package Foo::Bar;
    use Moose;

    ::is( ::exception { extends 'Foo', 'Bar' }, undef, 'loaded Foo and (inline) Bar superclass correctly' );
}

{

    package Bling;
    use Moose;

    ::like( ::exception { extends 'No::Class' }, qr{Can't locate No/Class\.pm in \@INC}, 'correct error when superclass could not be found' );
}

{
    package Affe;
    our $VERSION = 23;
}

{
    package Tiger;
    use Moose;

    ::is( ::exception { extends 'Foo', Affe => { -version => 13 } }, undef, 'extends with version requirement' );
}

{
    package Birne;
    use Moose;

    ::like( ::exception { extends 'Foo', Affe => { -version => 42 } }, qr/Affe version 42 required--this is only version 23/, 'extends with unsatisfied version requirement' );
}

done_testing;
