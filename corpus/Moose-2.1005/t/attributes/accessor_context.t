#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
use Test::Fatal;

is( exception {
    package My::Class;
    use Moose;

    has s_rw => (
        is => 'rw',
    );

    has s_ro => (
        is => 'ro',
    );

    has a_rw => (
        is  => 'rw',
        isa => 'ArrayRef',

        auto_deref => 1,
    );

    has a_ro => (
        is  => 'ro',
        isa => 'ArrayRef',

        auto_deref => 1,
    );

    has h_rw => (
        is  => 'rw',
        isa => 'HashRef',

        auto_deref => 1,
    );

    has h_ro => (
        is  => 'ro',
        isa => 'HashRef',

        auto_deref => 1,
    );
}, undef, 'class definition' );

is( exception {
    my $o = My::Class->new();

    is_deeply [scalar $o->s_rw], [undef], 'uninitialized scalar attribute/rw in scalar context';
    is_deeply [$o->s_rw],        [undef], 'uninitialized scalar attribute/rw in list context';
    is_deeply [scalar $o->s_ro], [undef], 'uninitialized scalar attribute/ro in scalar context';
    is_deeply [$o->s_ro],        [undef], 'uninitialized scalar attribute/ro in list context';


    is_deeply [scalar $o->a_rw], [undef], 'uninitialized ArrayRef attribute/rw in scalar context';
    is_deeply [$o->a_rw],        [],      'uninitialized ArrayRef attribute/rw in list context';
    is_deeply [scalar $o->a_ro], [undef], 'uninitialized ArrayRef attribute/ro in scalar context';
    is_deeply [$o->a_ro],        [],      'uninitialized ArrayRef attribute/ro in list context';

    is_deeply [scalar $o->h_rw], [undef], 'uninitialized HashRef attribute/rw in scalar context';
    is_deeply [$o->h_rw],        [],      'uninitialized HashRef attribute/rw in list context';
    is_deeply [scalar $o->h_ro], [undef], 'uninitialized HashRef attribute/ro in scalar context';
    is_deeply [$o->h_ro],        [],      'uninitialized HashRef attribute/ro in list context';

}, undef, 'testing' );

done_testing;
