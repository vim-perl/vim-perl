#!/usr/bin/perl

use strict;
use warnings;

use Test::More;


## Roles

{
    package Constraint;
    use Moose::Role;

    has 'value' => (isa => 'Num', is => 'ro');

    around 'validate' => sub {
        my $c = shift;
        my ($self, $field) = @_;
        return undef if $c->($self, $self->validation_value($field));
        return $self->error_message;
    };

    sub validation_value {
        my ($self, $field) = @_;
        return $field;
    }

    sub error_message { confess "Abstract method!" }

    package Constraint::OnLength;
    use Moose::Role;

    has 'units' => (isa => 'Str', is => 'ro');

    override 'validation_value' => sub {
        return length(super());
    };

    override 'error_message' => sub {
        my $self = shift;
        return super() . ' ' . $self->units;
    };

}

## Classes

{
    package Constraint::AtLeast;
    use Moose;

    with 'Constraint';

    sub validate {
        my ($self, $field) = @_;
        ($field >= $self->value);
    }

    sub error_message { 'must be at least ' . (shift)->value; }

    package Constraint::NoMoreThan;
    use Moose;

    with 'Constraint';

    sub validate {
        my ($self, $field) = @_;
        ($field <= $self->value);
    }

    sub error_message { 'must be no more than ' . (shift)->value; }

    package Constraint::LengthNoMoreThan;
    use Moose;

    extends 'Constraint::NoMoreThan';
       with 'Constraint::OnLength';

    package Constraint::LengthAtLeast;
    use Moose;

    extends 'Constraint::AtLeast';
       with 'Constraint::OnLength';
}

my $no_more_than_10 = Constraint::NoMoreThan->new(value => 10);
isa_ok($no_more_than_10, 'Constraint::NoMoreThan');

ok($no_more_than_10->does('Constraint'), '... Constraint::NoMoreThan does Constraint');

ok(!defined($no_more_than_10->validate(1)), '... validated correctly');
is($no_more_than_10->validate(11), 'must be no more than 10', '... validation failed correctly');

my $at_least_10 = Constraint::AtLeast->new(value => 10);
isa_ok($at_least_10, 'Constraint::AtLeast');

ok($at_least_10->does('Constraint'), '... Constraint::AtLeast does Constraint');

ok(!defined($at_least_10->validate(11)), '... validated correctly');
is($at_least_10->validate(1), 'must be at least 10', '... validation failed correctly');

# onlength

my $no_more_than_10_chars = Constraint::LengthNoMoreThan->new(value => 10, units => 'chars');
isa_ok($no_more_than_10_chars, 'Constraint::LengthNoMoreThan');
isa_ok($no_more_than_10_chars, 'Constraint::NoMoreThan');

ok($no_more_than_10_chars->does('Constraint'), '... Constraint::LengthNoMoreThan does Constraint');
ok($no_more_than_10_chars->does('Constraint::OnLength'), '... Constraint::LengthNoMoreThan does Constraint::OnLength');

ok(!defined($no_more_than_10_chars->validate('foo')), '... validated correctly');
is($no_more_than_10_chars->validate('foooooooooo'),
    'must be no more than 10 chars',
    '... validation failed correctly');

my $at_least_10_chars = Constraint::LengthAtLeast->new(value => 10, units => 'chars');
isa_ok($at_least_10_chars, 'Constraint::LengthAtLeast');
isa_ok($at_least_10_chars, 'Constraint::AtLeast');

ok($at_least_10_chars->does('Constraint'), '... Constraint::LengthAtLeast does Constraint');
ok($at_least_10_chars->does('Constraint::OnLength'), '... Constraint::LengthAtLeast does Constraint::OnLength');

ok(!defined($at_least_10_chars->validate('barrrrrrrrr')), '... validated correctly');
is($at_least_10_chars->validate('bar'), 'must be at least 10 chars', '... validation failed correctly');

done_testing;
