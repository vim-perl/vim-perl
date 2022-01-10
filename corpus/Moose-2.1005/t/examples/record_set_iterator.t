#!/usr/bin/perl

use strict;
use warnings;

use Test::More;


{
    package Record;
    use Moose;

    has 'first_name' => (is => 'ro', isa => 'Str');
    has 'last_name'  => (is => 'ro', isa => 'Str');

    package RecordSet;
    use Moose;

    has 'data' => (
        is      => 'ro',
        isa     => 'ArrayRef[Record]',
        default => sub { [] },
    );

    has 'index' => (
        is      => 'rw',
        isa     => 'Int',
        default => sub { 0 },
    );

    sub next {
        my $self = shift;
        my $i = $self->index;
        $self->index($i + 1);
        return $self->data->[$i];
    }

    package RecordSetIterator;
    use Moose;

    has 'record_set' => (
        is  => 'rw',
        isa => 'RecordSet',
    );

    # list the fields you want to
    # fetch from the current record
    my @fields = Record->meta->get_attribute_list;

    has 'current_record' => (
        is      => 'rw',
        isa     => 'Record',
        lazy    => 1,
        default => sub {
            my $self = shift;
            $self->record_set->next() # grab the first one
        },
        trigger => sub {
            my $self = shift;
            # whenever this attribute is
            # updated, it will clear all
            # the fields for you.
            $self->$_() for map { '_clear_' . $_ } @fields;
        }
    );

    # define the attributes
    # for all the fields.
    for my $field (@fields) {
        has $field => (
            is      => 'ro',
            isa     => 'Any',
            lazy    => 1,
            default => sub {
                my $self = shift;
                # fetch the value from
                # the current record
                $self->current_record->$field();
            },
            # make sure they have a clearer ..
            clearer => ('_clear_' . $field)
        );
    }

    sub get_next_record {
        my $self = shift;
        $self->current_record($self->record_set->next());
    }
}

my $rs = RecordSet->new(
    data => [
        Record->new(first_name => 'Bill', last_name => 'Smith'),
        Record->new(first_name => 'Bob', last_name => 'Jones'),
        Record->new(first_name => 'Jim', last_name => 'Johnson'),
    ]
);
isa_ok($rs, 'RecordSet');

my $rsi = RecordSetIterator->new(record_set => $rs);
isa_ok($rsi, 'RecordSetIterator');

is($rsi->first_name, 'Bill', '... got the right first name');
is($rsi->last_name, 'Smith', '... got the right last name');

$rsi->get_next_record;

is($rsi->first_name, 'Bob', '... got the right first name');
is($rsi->last_name, 'Jones', '... got the right last name');

$rsi->get_next_record;

is($rsi->first_name, 'Jim', '... got the right first name');
is($rsi->last_name, 'Johnson', '... got the right last name');

done_testing;
