#!/usr/bin/perl

# In the case where a child type constraint's parent constraint fails,
# the exception should reference the parent type constraint that actually
# failed instead of always referencing the child'd type constraint

use strict;
use warnings;

use Test::More;
use Test::Fatal;

use Moose::Util::TypeConstraints;

is( exception {
    subtype 'ParentConstraint' => as 'Str' => where {0};
}, undef, 'specified parent type constraint' );

my $tc;
is( exception {
    $tc = subtype 'ChildConstraint' => as 'ParentConstraint' => where {1};
}, undef, 'specified child type constraint' );

{
    my $errmsg = $tc->validate();

    TODO: {
        local $TODO = 'Not yet supported';
        ok($errmsg !~ /Validation failed for 'ChildConstraint'/, 'exception references failing parent constraint');
    };
}

done_testing;
