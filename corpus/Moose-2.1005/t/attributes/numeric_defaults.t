#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::Moose;
use B;

{
    package Foo;
    use Moose;

    has foo => (is => 'ro', default => 100);

    sub bar { 100 }
}

with_immutable {
    my $foo = Foo->new;
    for my $meth (qw(foo bar)) {
        my $val = $foo->$meth;
        my $b = B::svref_2object(\$val);
        my $flags = $b->FLAGS;
        ok($flags & B::SVf_IOK || $flags & B::SVp_IOK, "it's an int");
        ok(!($flags & B::SVf_POK), "not a string");
    }
} 'Foo';

{
    package Bar;
    use Moose;

    has foo => (is => 'ro', lazy => 1, default => 100);

    sub bar { 100 }
}

with_immutable {
    my $bar = Bar->new;
    for my $meth (qw(foo bar)) {
        my $val = $bar->$meth;
        my $b = B::svref_2object(\$val);
        my $flags = $b->FLAGS;
        ok($flags & B::SVf_IOK || $flags & B::SVp_IOK, "it's an int");
        ok(!($flags & B::SVf_POK), "not a string");
    }
} 'Bar';

{
    package Baz;
    use Moose;

    has foo => (is => 'ro', isa => 'Int', lazy => 1, default => 100);

    sub bar { 100 }
}

with_immutable {
    my $baz = Baz->new;
    for my $meth (qw(foo bar)) {
        my $val = $baz->$meth;
        my $b = B::svref_2object(\$val);
        my $flags = $b->FLAGS;
        ok($flags & B::SVf_IOK || $flags & B::SVp_IOK, "it's an int");
        ok(!($flags & B::SVf_POK), "not a string");
    }
} 'Baz';

{
    package Foo2;
    use Moose;

    has foo => (is => 'ro', default => 10.5);

    sub bar { 10.5 }
}

with_immutable {
    my $foo2 = Foo2->new;
    for my $meth (qw(foo bar)) {
        my $val = $foo2->$meth;
        my $b = B::svref_2object(\$val);
        my $flags = $b->FLAGS;
        ok($flags & B::SVf_NOK || $flags & B::SVp_NOK, "it's a num");
        ok(!($flags & B::SVf_POK), "not a string");
    }
} 'Foo2';

{
    package Bar2;
    use Moose;

    has foo => (is => 'ro', lazy => 1, default => 10.5);

    sub bar { 10.5 }
}

with_immutable {
    my $bar2 = Bar2->new;
    for my $meth (qw(foo bar)) {
        my $val = $bar2->$meth;
        my $b = B::svref_2object(\$val);
        my $flags = $b->FLAGS;
        ok($flags & B::SVf_NOK || $flags & B::SVp_NOK, "it's a num");
        ok(!($flags & B::SVf_POK), "not a string");
    }
} 'Bar2';

{
    package Baz2;
    use Moose;

    has foo => (is => 'ro', isa => 'Num', lazy => 1, default => 10.5);

    sub bar { 10.5 }
}

with_immutable {
    my $baz2 = Baz2->new;
    for my $meth (qw(foo bar)) {
        my $val = $baz2->$meth;
        my $b = B::svref_2object(\$val);
        my $flags = $b->FLAGS;
        ok($flags & B::SVf_NOK || $flags & B::SVp_NOK, "it's a num");
        # it's making sure that the Num value doesn't get converted to a string for regex matching
        # this is the reason for using a temporary variable, $val for regex matching,
        # instead of $_[1] in Num implementation in lib/Moose/Util/TypeConstraints/Builtins.pm
        ok(!($flags & B::SVf_POK), "not a string");
    }
} 'Baz2';

done_testing;
