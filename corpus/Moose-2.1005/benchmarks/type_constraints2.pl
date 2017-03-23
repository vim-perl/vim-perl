#!/usr/bin/perl

use strict;
use warnings;

use Benchmark qw[timethese];

=pod

This benchmark is designed to measure how long things with type constraints
take (constructors, accessors). It was created to measure the impact of
inlining type constraints.

=cut

{
    package Thing;

    use Moose;

    has int => (
        is  => 'rw',
        isa => 'Int',
    );

    has str => (
        is  => 'rw',
        isa => 'Str',
    );

    has fh => (
        is  => 'rw',
        isa => 'FileHandle',
    );

    has object => (
        is  => 'rw',
        isa => 'Object',
    );

    has a_int => (
        is  => 'rw',
        isa => 'ArrayRef[Int]',
    );

    has a_str => (
        is  => 'rw',
        isa => 'ArrayRef[Str]',
    );

    has a_fh => (
        is  => 'rw',
        isa => 'ArrayRef[FileHandle]',
    );

    has a_object => (
        is  => 'rw',
        isa => 'ArrayRef[Object]',
    );

    has h_int => (
        is  => 'rw',
        isa => 'HashRef[Int]',
    );

    has h_str => (
        is  => 'rw',
        isa => 'HashRef[Str]',
    );

    has h_fh => (
        is  => 'rw',
        isa => 'HashRef[FileHandle]',
    );

    has h_object => (
        is  => 'rw',
        isa => 'HashRef[Object]',
    );

    __PACKAGE__->meta->make_immutable;
}

{
    package Simple;
    use Moose;

    has str => (
        is  => 'rw',
        isa => 'Str',
    );

    __PACKAGE__->meta->make_immutable;
}

my @ints    = 1 .. 10;
my @strs    = 'a' .. 'j';
my @fhs     = map { my $fh; open $fh, '<', $0 or die; $fh; } 1 .. 10;
my @objects = map { Thing->new } 1 .. 10;

my %ints    = map { $_ => $_ } @ints;
my %strs    = map { $_ => $_ } @ints;
my %fhs     = map { $_ => $_ } @fhs;
my %objects = map { $_ => $_ } @objects;

my $thing = Thing->new;
my $simple = Simple->new;

timethese(
    1_000_000, {
        constructor_simple => sub {
            Simple->new( str => $strs[0] );
        },
        accessors_simple => sub {
            $simple->str( $strs[0] );
        },
    }
);

timethese(
    20_000, {
        constructor_all => sub {
            Thing->new(
                int      => $ints[0],
                str      => $strs[0],
                fh       => $fhs[0],
                object   => $objects[0],
                a_int    => \@ints,
                a_str    => \@strs,
                a_fh     => \@fhs,
                a_object => \@objects,
                h_int    => \%ints,
                h_str    => \%strs,
                h_fh     => \%fhs,
                h_object => \%objects,
            );
        },
        accessors_all => sub {
            $thing->int( $ints[0] );
            $thing->str( $strs[0] );
            $thing->fh( $fhs[0] );
            $thing->object( $objects[0] );
            $thing->a_int( \@ints );
            $thing->a_str( \@strs );
            $thing->a_fh( \@fhs );
            $thing->a_object( \@objects );
            $thing->h_int( \%ints );
            $thing->h_str( \%strs );
            $thing->h_fh( \%fhs );
            $thing->h_object( \%objects );
        },
    }
);

