#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;

use Moose::Util::TypeConstraints;
use Moose::Meta::TypeConstraint::Parameterized;

BEGIN {
    package MyList;
    sub new {
        my $class = shift;
        bless { items => \@_ }, $class;
    }

    sub items {
        my $self = shift;
        return @{ $self->{items} };
    }
}

subtype 'MyList' => as 'Object' => where { $_->isa('MyList') };

is( exception {
    coerce 'ArrayRef'
        => from 'MyList'
            => via { [ $_->items ] }
}, undef, '... created the coercion okay' );

my $mylist = Moose::Util::TypeConstraints::find_or_parse_type_constraint('MyList[Int]');

ok($mylist->check(MyList->new(10, 20, 30)), '... validated it correctly (pass)');
ok(!$mylist->check(MyList->new(10, "two")), '... validated it correctly (fail)');
ok(!$mylist->check([10]), '... validated it correctly (fail)');

subtype 'EvenList' => as 'MyList' => where { $_->items % 2 == 0 };

# XXX: get this to work *without* the declaration. I suspect it'll be a new
# method in Moose::Meta::TypeCoercion that will look at the parents of the
# coerced type as well. but will that be too "action at a distance"-ey?
is( exception {
    coerce 'ArrayRef'
        => from 'EvenList'
            => via { [ $_->items ] }
}, undef, '... created the coercion okay' );

my $evenlist = Moose::Util::TypeConstraints::find_or_parse_type_constraint('EvenList[Int]');

ok(!$evenlist->check(MyList->new(10, 20, 30)), '... validated it correctly (fail)');
ok($evenlist->check(MyList->new(10, 20, 30, 40)), '... validated it correctly (pass)');
ok(!$evenlist->check(MyList->new(10, "two")), '... validated it correctly (fail)');
ok(!$evenlist->check([10, 20]), '... validated it correctly (fail)');

done_testing;
