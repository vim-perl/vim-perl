#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;
use Moose::Meta::Class;
use Moose::Util;

use lib 't/lib', 'lib';


# Note that this test passed (pre svn #5543) if we inlined the role
# definitions in this file, as it was very timing sensitive.
is( exception {
    my $builder_meta = Moose::Meta::Class->create(
        'YATTA' => (
            superclass => 'Moose::Meta::Class',
            roles      => [qw( Role::Interface Role::Child )],
        )
    );
}, undef, 'Create a new class with several roles' );

done_testing;
