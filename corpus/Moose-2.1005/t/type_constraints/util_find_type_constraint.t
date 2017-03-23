#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Moose::Util::TypeConstraints;

foreach my $type_name (qw(
    Any
    Item
        Bool
        Undef
        Defined
            Value
                Num
                  Int
                Str
            Ref
                ScalarRef
                ArrayRef
                HashRef
                CodeRef
                RegexpRef
                Object
    )) {
    is(find_type_constraint($type_name)->name,
       $type_name,
       '... got the right name for ' . $type_name);
}

# TODO:
# add tests for is_subtype_of which confirm the hierarchy

done_testing;
