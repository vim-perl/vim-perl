#!/usr/bin/perl -w

use strict;
use Test::More 'no_plan';
use Test::Fatal;
$| = 1;



# =begin testing SETUP
{

  package Eq;
  use Moose::Role;

  requires 'equal_to';

  sub not_equal_to {
      my ( $self, $other ) = @_;
      not $self->equal_to($other);
  }

  package Comparable;
  use Moose::Role;

  with 'Eq';

  requires 'compare';

  sub equal_to {
      my ( $self, $other ) = @_;
      $self->compare($other) == 0;
  }

  sub greater_than {
      my ( $self, $other ) = @_;
      $self->compare($other) == 1;
  }

  sub less_than {
      my ( $self, $other ) = @_;
      $self->compare($other) == -1;
  }

  sub greater_than_or_equal_to {
      my ( $self, $other ) = @_;
      $self->greater_than($other) || $self->equal_to($other);
  }

  sub less_than_or_equal_to {
      my ( $self, $other ) = @_;
      $self->less_than($other) || $self->equal_to($other);
  }

  package Printable;
  use Moose::Role;

  requires 'to_string';

  package US::Currency;
  use Moose;

  with 'Comparable', 'Printable';

  has 'amount' => ( is => 'rw', isa => 'Num', default => 0 );

  sub compare {
      my ( $self, $other ) = @_;
      $self->amount <=> $other->amount;
  }

  sub to_string {
      my $self = shift;
      sprintf '$%0.2f USD' => $self->amount;
  }
}



# =begin testing
{
ok( US::Currency->does('Comparable'), '... US::Currency does Comparable' );
ok( US::Currency->does('Eq'),         '... US::Currency does Eq' );
ok( US::Currency->does('Printable'),  '... US::Currency does Printable' );

my $hundred = US::Currency->new( amount => 100.00 );
isa_ok( $hundred, 'US::Currency' );

ok( $hundred->DOES("US::Currency"), "UNIVERSAL::DOES for class" );
ok( $hundred->DOES("Comparable"),   "UNIVERSAL::DOES for role" );

can_ok( $hundred, 'amount' );
is( $hundred->amount, 100, '... got the right amount' );

can_ok( $hundred, 'to_string' );
is( $hundred->to_string, '$100.00 USD',
    '... got the right stringified value' );

ok( $hundred->does('Comparable'), '... US::Currency does Comparable' );
ok( $hundred->does('Eq'),         '... US::Currency does Eq' );
ok( $hundred->does('Printable'),  '... US::Currency does Printable' );

my $fifty = US::Currency->new( amount => 50.00 );
isa_ok( $fifty, 'US::Currency' );

can_ok( $fifty, 'amount' );
is( $fifty->amount, 50, '... got the right amount' );

can_ok( $fifty, 'to_string' );
is( $fifty->to_string, '$50.00 USD', '... got the right stringified value' );

ok( $hundred->greater_than($fifty),             '... 100 gt 50' );
ok( $hundred->greater_than_or_equal_to($fifty), '... 100 ge 50' );
ok( !$hundred->less_than($fifty),               '... !100 lt 50' );
ok( !$hundred->less_than_or_equal_to($fifty),   '... !100 le 50' );
ok( !$hundred->equal_to($fifty),                '... !100 eq 50' );
ok( $hundred->not_equal_to($fifty),             '... 100 ne 50' );

ok( !$fifty->greater_than($hundred),             '... !50 gt 100' );
ok( !$fifty->greater_than_or_equal_to($hundred), '... !50 ge 100' );
ok( $fifty->less_than($hundred),                 '... 50 lt 100' );
ok( $fifty->less_than_or_equal_to($hundred),     '... 50 le 100' );
ok( !$fifty->equal_to($hundred),                 '... !50 eq 100' );
ok( $fifty->not_equal_to($hundred),              '... 50 ne 100' );

ok( !$fifty->greater_than($fifty),            '... !50 gt 50' );
ok( $fifty->greater_than_or_equal_to($fifty), '... !50 ge 50' );
ok( !$fifty->less_than($fifty),               '... 50 lt 50' );
ok( $fifty->less_than_or_equal_to($fifty),    '... 50 le 50' );
ok( $fifty->equal_to($fifty),                 '... 50 eq 50' );
ok( !$fifty->not_equal_to($fifty),            '... !50 ne 50' );

## ... check some meta-stuff

# Eq

my $eq_meta = Eq->meta;
isa_ok( $eq_meta, 'Moose::Meta::Role' );

ok( $eq_meta->has_method('not_equal_to'), '... Eq has_method not_equal_to' );
ok( $eq_meta->requires_method('equal_to'),
    '... Eq requires_method not_equal_to' );

# Comparable

my $comparable_meta = Comparable->meta;
isa_ok( $comparable_meta, 'Moose::Meta::Role' );

ok( $comparable_meta->does_role('Eq'), '... Comparable does Eq' );

foreach my $method_name (
    qw(
    equal_to not_equal_to
    greater_than greater_than_or_equal_to
    less_than less_than_or_equal_to
    )
    ) {
    ok( $comparable_meta->has_method($method_name),
        '... Comparable has_method ' . $method_name );
}

ok( $comparable_meta->requires_method('compare'),
    '... Comparable requires_method compare' );

# Printable

my $printable_meta = Printable->meta;
isa_ok( $printable_meta, 'Moose::Meta::Role' );

ok( $printable_meta->requires_method('to_string'),
    '... Printable requires_method to_string' );

# US::Currency

my $currency_meta = US::Currency->meta;
isa_ok( $currency_meta, 'Moose::Meta::Class' );

ok( $currency_meta->does_role('Comparable'),
    '... US::Currency does Comparable' );
ok( $currency_meta->does_role('Eq'), '... US::Currency does Eq' );
ok( $currency_meta->does_role('Printable'),
    '... US::Currency does Printable' );

foreach my $method_name (
    qw(
    amount
    equal_to not_equal_to
    compare
    greater_than greater_than_or_equal_to
    less_than less_than_or_equal_to
    to_string
    )
    ) {
    ok( $currency_meta->has_method($method_name),
        '... US::Currency has_method ' . $method_name );
}
}




1;
