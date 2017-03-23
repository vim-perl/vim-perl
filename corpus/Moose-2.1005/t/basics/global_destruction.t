#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

{
    package Foo;
    use Moose;

    sub DEMOLISH {
        my $self = shift;
        my ($igd) = @_;
        ::ok(
            !$igd,
            'in_global_destruction state is passed to DEMOLISH properly (false)'
        );
    }
}

{
    my $foo = Foo->new;
}

{
    package Bar;
    use Moose;

    sub DEMOLISH {
        my $self = shift;
        my ($igd) = @_;
        ::ok(
            !$igd,
            'in_global_destruction state is passed to DEMOLISH properly (false)'
        );
    }

    __PACKAGE__->meta->make_immutable;
}

{
    my $bar = Bar->new;
}

ok(
    $_,
    'in_global_destruction state is passed to DEMOLISH properly (true)'
) for split //, `$^X t/basics/global-destruction-helper.pl`;

done_testing;
