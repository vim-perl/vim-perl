#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Moose ();

do {
    package My::Meta::Role;
    use Moose;
    extends 'Moose::Meta::Role';

    has test_serial => (
        is      => 'ro',
        isa     => 'Int',
        default => 1,
    );

    no Moose;
};

my $role = My::Meta::Role->create_anon_role;
is($role->test_serial, 1, "default value for the serial attribute");

my $nine_role = My::Meta::Role->create_anon_role(test_serial => 9);
is($nine_role->test_serial, 9, "parameter value for the serial attribute");

done_testing;
