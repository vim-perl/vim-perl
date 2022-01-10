#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

my @called;

do {
    package Class;
    use Moose;

    sub DEMOLISH {
        push @called, 'Class::DEMOLISH';
    }

    sub DEMOLISHALL {
        my $self = shift;
        push @called, 'Class::DEMOLISHALL';
        $self->SUPER::DEMOLISHALL(@_);
    }

    package Child;
    use Moose;
    extends 'Class';

    sub DEMOLISH {
        push @called, 'Child::DEMOLISH';
    }

    sub DEMOLISHALL {
        my $self = shift;
        push @called, 'Child::DEMOLISHALL';
        $self->SUPER::DEMOLISHALL(@_);
    }
};

is_deeply([splice @called], [], "no DEMOLISH calls yet");

do {
    my $object = Class->new;

    is_deeply([splice @called], [], "no DEMOLISH calls yet");
};

is_deeply([splice @called], ['Class::DEMOLISHALL', 'Class::DEMOLISH']);

do {
    my $child = Child->new;
    is_deeply([splice @called], [], "no DEMOLISH calls yet");

};

is_deeply([splice @called], ['Child::DEMOLISHALL', 'Class::DEMOLISHALL', 'Child::DEMOLISH', 'Class::DEMOLISH']);

done_testing;
