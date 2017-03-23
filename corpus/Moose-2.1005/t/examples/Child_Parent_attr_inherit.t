#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

=pod

Some examples of triggers and how they can
be used to manage parent-child relationships.

=cut

{

    package Parent;
    use Moose;

    has 'last_name' => (
        is      => 'rw',
        isa     => 'Str',
        trigger => sub {
            my $self = shift;

            # if the parents last-name changes
            # then so do all the childrens
            foreach my $child ( @{ $self->children } ) {
                $child->last_name( $self->last_name );
            }
        }
    );

    has 'children' =>
        ( is => 'rw', isa => 'ArrayRef', default => sub { [] } );
}
{

    package Child;
    use Moose;

    has 'parent' => (
        is       => 'rw',
        isa      => 'Parent',
        required => 1,
        trigger  => sub {
            my $self = shift;

            # if the parent is changed,..
            # make sure we update
            $self->last_name( $self->parent->last_name );
        }
    );

    has 'last_name' => (
        is      => 'rw',
        isa     => 'Str',
        lazy    => 1,
        default => sub { (shift)->parent->last_name }
    );

}

my $parent = Parent->new( last_name => 'Smith' );
isa_ok( $parent, 'Parent' );

is( $parent->last_name, 'Smith',
    '... the parent has the last name we expected' );

$parent->children( [ map { Child->new( parent => $parent ) } ( 0 .. 3 ) ] );

foreach my $child ( @{ $parent->children } ) {
    is( $child->last_name, $parent->last_name,
              '... parent and child have the same last name ('
            . $parent->last_name
            . ')' );
}

$parent->last_name('Jones');
is( $parent->last_name, 'Jones', '... the parent has the new last name' );

foreach my $child ( @{ $parent->children } ) {
    is( $child->last_name, $parent->last_name,
              '... parent and child have the same last name ('
            . $parent->last_name
            . ')' );
}

# make a new parent

my $parent2 = Parent->new( last_name => 'Brown' );
isa_ok( $parent2, 'Parent' );

# orphan the child

my $orphan = pop @{ $parent->children };

# and then the new parent adopts it

$orphan->parent($parent2);

foreach my $child ( @{ $parent->children } ) {
    is( $child->last_name, $parent->last_name,
              '... parent and child have the same last name ('
            . $parent->last_name
            . ')' );
}

isnt( $orphan->last_name, $parent->last_name,
          '... the orphan child does not have the same last name anymore ('
        . $parent2->last_name
        . ')' );
is( $orphan->last_name, $parent2->last_name,
          '... parent2 and orphan child have the same last name ('
        . $parent2->last_name
        . ')' );

# make sure that changes still will not propagate

$parent->last_name('Miller');
is( $parent->last_name, 'Miller',
    '... the parent has the new last name (again)' );

foreach my $child ( @{ $parent->children } ) {
    is( $child->last_name, $parent->last_name,
              '... parent and child have the same last name ('
            . $parent->last_name
            . ')' );
}

isnt( $orphan->last_name, $parent->last_name,
    '... the orphan child is not affected by changes in the parent anymore' );
is( $orphan->last_name, $parent2->last_name,
          '... parent2 and orphan child have the same last name ('
        . $parent2->last_name
        . ')' );

done_testing;
