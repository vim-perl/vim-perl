#!/usr/bin/perl -w

use strict;
use Test::More 'no_plan';
use Test::Fatal;
$| = 1;



# =begin testing SETUP
use Test::Requires {
    'Test::Output' => '0',
};



# =begin testing SETUP
{

  package MooseX::Debugging;

  use Moose::Exporter;

  Moose::Exporter->setup_import_methods(
      base_class_roles => ['MooseX::Debugging::Role::Object'],
  );

  package MooseX::Debugging::Role::Object;

  use Moose::Role;

  sub BUILD {}
  after BUILD => sub {
      my $self = shift;

      warn "Made a new " . ( ref $self ) . " object\n";
  };
}



# =begin testing
{
{
    package Debugged;

    use Moose;
    MooseX::Debugging->import;
}

stderr_is(
    sub { Debugged->new },
    "Made a new Debugged object\n",
    'got expected output from debugging role'
);
}




1;
