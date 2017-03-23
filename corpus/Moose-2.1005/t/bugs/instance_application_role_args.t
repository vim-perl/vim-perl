#!/usr/bin/perl
use strict;
use warnings;
use Test::More;

{
    package Point;
    use Moose;

    with qw/DoesNegated DoesTranspose/;

    has x => ( isa => 'Int', is => 'rw' );
    has y => ( isa => 'Int', is => 'rw' );

    sub inspect { [$_[0]->x, $_[0]->y] }

    no Moose;
}

{
    package DoesNegated;
    use Moose::Role;

    sub negated {
        my $self = shift;
        $self->new( x => -$self->x, y => -$self->y );
    }

    no Moose::Role;
}

{
    package DoesTranspose;
    use Moose::Role;

    sub transpose {
        my $self = shift;
        $self->new( x => $self->y, y => $self->x );
    }

    no Moose::Role;
}

my $p = Point->new( x => 4, y => 3 );

DoesTranspose->meta->apply( $p, -alias => { transpose => 'negated' } );

is_deeply($p->negated->inspect, [3, 4]);
is_deeply($p->transpose->inspect, [3, 4]);

done_testing;
