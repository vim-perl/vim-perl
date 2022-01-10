#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;
use Test::Moose qw(with_immutable);
use Scalar::Util 'blessed';

use Moose::Util::TypeConstraints;

subtype 'Positive'
     => as 'Num'
     => where { $_ > 0 };

{
    package Parent;
    use Moose;

    has name => (
        is       => 'rw',
        isa      => 'Str',
    );

    has lazy_classname => (
        is      => 'ro',
        lazy    => 1,
        default => sub { "Parent" },
    );

    has type_constrained => (
        is      => 'rw',
        isa     => 'Num',
        default => 5.5,
    );

    package Child;
    use Moose;
    extends 'Parent';

    has '+name' => (
        default => 'Junior',
    );

    has '+lazy_classname' => (
        default => sub {"Child"},
    );

    has '+type_constrained' => (
        isa     => 'Int',
        default => 100,
    );

    our %trigger_calls;
    our %initializer_calls;

    has new_attr => (
        is      => 'rw',
        isa     => 'Str',
        trigger => sub {
            my ( $self, $val, $attr ) = @_;
            $trigger_calls{new_attr}++;
        },
        initializer => sub {
            my ( $self, $value, $set, $attr ) = @_;
            $initializer_calls{new_attr}++;
            $set->($value);
        },
    );
}

my @classes = qw(Parent Child);

with_immutable {
    my $foo = Parent->new;
    my $bar = Parent->new;

    is( blessed($foo),        'Parent', 'Parent->new gives a Parent object' );
    is( $foo->name,           undef,    'No name yet' );
    is( $foo->lazy_classname, 'Parent', "lazy attribute initialized" );
    is(
        exception { $foo->type_constrained(10.5) }, undef,
        "Num type constraint for now.."
    );

    # try to rebless, except it will fail due to Child's stricter type constraint
    like(
        exception { Child->meta->rebless_instance($foo) },
        qr/^Attribute \(type_constrained\) does not pass the type constraint because\: Validation failed for 'Int' with value 10\.5/,
        '... this failed because of type check'
    );
    like(
        exception { Child->meta->rebless_instance($bar) },
        qr/^Attribute \(type_constrained\) does not pass the type constraint because\: Validation failed for 'Int' with value 5\.5/,
        '... this failed because of type check'
    );

    $foo->type_constrained(10);
    $bar->type_constrained(5);

    Child->meta->rebless_instance($foo);
    Child->meta->rebless_instance( $bar, new_attr => 'blah' );

    is( blessed($foo), 'Child',  'successfully reblessed into Child' );
    is( $foo->name,    'Junior', "Child->name's default came through" );

    is(
        $foo->lazy_classname, 'Parent',
        "lazy attribute was already initialized"
    );
    is(
        $bar->lazy_classname, 'Child',
        "lazy attribute just now initialized"
    );

    like(
        exception { $foo->type_constrained(10.5) },
        qr/^Attribute \(type_constrained\) does not pass the type constraint because\: Validation failed for 'Int' with value 10\.5/,
        '... this failed because of type check'
    );

    is_deeply(
        \%Child::trigger_calls, { new_attr => 1 },
        'Trigger fired on rebless_instance'
    );
    is_deeply(
        \%Child::initializer_calls, { new_attr => 1 },
        'Initializer fired on rebless_instance'
    );

    undef %Child::trigger_calls;
    undef %Child::initializer_calls;

}
@classes;

done_testing;
