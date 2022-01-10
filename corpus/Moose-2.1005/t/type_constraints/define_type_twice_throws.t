#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;

use Moose::Util::TypeConstraints;

{
    package Some::Class;
    use Moose::Util::TypeConstraints;

    subtype 'MySubType' => as 'Int' => where { 1 };
}

like( exception {
    package Some::Other::Class;
    use Moose::Util::TypeConstraints;

    subtype 'MySubType' => as 'Int' => where { 1 };
}, qr/cannot be created again/, 'Trying to create same type twice throws' );

done_testing;
