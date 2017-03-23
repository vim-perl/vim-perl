#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;

is( exception {
    package MooseX::Attribute::Test;
    use Moose::Role;
}, undef, 'creating custom attribute "metarole" is okay' );

is( exception {
    package Moose::Meta::Attribute::Custom::Test;
    use Moose;

    extends 'Moose::Meta::Attribute';
    with 'MooseX::Attribute::Test';
}, undef, 'custom attribute metaclass extending role is okay' );

done_testing;
