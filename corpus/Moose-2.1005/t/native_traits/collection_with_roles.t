#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

{
    package Subject;

    use Moose::Role;

    has observers => (
        traits     => ['Array'],
        is         => 'ro',
        isa        => 'ArrayRef[Observer]',
        auto_deref => 1,
        default    => sub { [] },
        handles    => {
            'add_observer'    => 'push',
            'count_observers' => 'count',
        },
    );

    sub notify {
        my ($self) = @_;
        foreach my $observer ( $self->observers() ) {
            $observer->update($self);
        }
    }
}

{
    package Observer;

    use Moose::Role;

    requires 'update';
}

{
    package Counter;

    use Moose;

    with 'Subject';

    has count => (
        traits  => ['Counter'],
        is      => 'ro',
        isa     => 'Int',
        default => 0,
        handles => {
            inc_counter => 'inc',
            dec_counter => 'dec',
        },
    );

    after qw(inc_counter dec_counter) => sub {
        my ($self) = @_;
        $self->notify();
    };
}

{

    package Display;

    use Test::More;

    use Moose;

    with 'Observer';

    sub update {
        my ( $self, $subject ) = @_;
        like $subject->count, qr{^-?\d+$},
            'Observed number ' . $subject->count;
    }
}

package main;

my $count = Counter->new();

ok( $count->can('add_observer'), 'add_observer method added' );

ok( $count->can('count_observers'), 'count_observers method added' );

ok( $count->can('inc_counter'), 'inc_counter method added' );

ok( $count->can('dec_counter'), 'dec_counter method added' );

$count->add_observer( Display->new() );

is( $count->count_observers, 1, 'Only one observer' );

is( $count->count, 0, 'Default to zero' );

$count->inc_counter;

is( $count->count, 1, 'Increment to one ' );

$count->inc_counter for ( 1 .. 6 );

is( $count->count, 7, 'Increment up to seven' );

$count->dec_counter;

is( $count->count, 6, 'Decrement to 6' );

$count->dec_counter for ( 1 .. 5 );

is( $count->count, 1, 'Decrement to 1' );

$count->dec_counter for ( 1 .. 2 );

is( $count->count, -1, 'Negative numbers' );

$count->inc_counter;

is( $count->count, 0, 'Back to zero' );

done_testing;
