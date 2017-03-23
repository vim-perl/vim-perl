#!/usr/bin/perl -w

use strict;
use Test::More 'no_plan';
use Test::Fatal;
$| = 1;



# =begin testing SETUP
{

  package MyApp::Base;
  use Moose;

  extends 'Moose::Object';

  before 'new' => sub { warn "Making a new " . $_[0] };

  no Moose;

  package MyApp::UseMyBase;
  use Moose ();
  use Moose::Exporter;

  Moose::Exporter->setup_import_methods( also => 'Moose' );

  sub init_meta {
      shift;
      return Moose->init_meta( @_, base_class => 'MyApp::Base' );
  }
}



# =begin testing SETUP
use Test::Requires {
    'Test::Output' => '0',
};



# =begin testing
{
{
    package Foo;

    MyApp::UseMyBase->import;

    has( 'size' => ( is => 'rw' ) );
}

ok( Foo->isa('MyApp::Base'), 'Foo isa MyApp::Base' );

ok( Foo->can('size'), 'Foo has a size method' );

my $foo;
stderr_like(
    sub { $foo = Foo->new( size => 2 ) },
    qr/^Making a new Foo/,
    'got expected warning when calling Foo->new'
);

is( $foo->size(), 2, '$foo->size is 2' );
}




1;
