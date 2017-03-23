#!/usr/bin/perl -w

use strict;
use Test::More 'no_plan';
use Test::Fatal;
$| = 1;



# =begin testing SETUP
{

  package MyApp::Meta::Attribute::Labeled;
  use Moose;
  extends 'Moose::Meta::Attribute';

  has label => (
      is        => 'rw',
      isa       => 'Str',
      predicate => 'has_label',
  );

  package Moose::Meta::Attribute::Custom::Labeled;
  sub register_implementation {'MyApp::Meta::Attribute::Labeled'}

  package MyApp::Website;
  use Moose;

  has url => (
      metaclass => 'Labeled',
      is        => 'rw',
      isa       => 'Str',
      label     => "The site's URL",
  );

  has name => (
      is  => 'rw',
      isa => 'Str',
  );

  sub dump {
      my $self = shift;

      my $meta = $self->meta;

      my $dump = '';

      for my $attribute ( map { $meta->get_attribute($_) }
          sort $meta->get_attribute_list ) {

          if (   $attribute->isa('MyApp::Meta::Attribute::Labeled')
              && $attribute->has_label ) {
              $dump .= $attribute->label;
          }
          else {
              $dump .= $attribute->name;
          }

          my $reader = $attribute->get_read_method;
          $dump .= ": " . $self->$reader . "\n";
      }

      return $dump;
  }

  package main;

  my $app = MyApp::Website->new( url => "http://google.com", name => "Google" );
}



# =begin testing
{
my $app = MyApp::Website->new( url => "http://google.com", name => "Google" );
is(
    $app->dump, q{name: Google
The site's URL: http://google.com
}, '... got the expected dump value'
);
}




1;
