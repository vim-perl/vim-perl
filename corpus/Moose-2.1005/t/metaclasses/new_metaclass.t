#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

do {
    package My::Meta::Class;
    use Moose;
    BEGIN { extends 'Moose::Meta::Class' };

    package Moose::Meta::Class::Custom::MyMetaClass;
    sub register_implementation { 'My::Meta::Class' }
};

do {
    package My::Class;
    use Moose -metaclass => 'My::Meta::Class';
};

do {
    package My::Class::Aliased;
    use Moose -metaclass => 'MyMetaClass';
};

is(My::Class->meta->meta->name, 'My::Meta::Class');
is(My::Class::Aliased->meta->meta->name, 'My::Meta::Class');

done_testing;
