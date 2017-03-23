#!/usr/bin/perl -w

use strict;
use Test::More 'no_plan';
use Test::Fatal;
$| = 1;



# =begin testing SETUP
{

  package MyApp::Mooseish;

  use Moose::Exporter;

  Moose::Exporter->setup_import_methods(
      with_meta       => ['has_table'],
      class_metaroles => {
          class => ['MyApp::Meta::Class::Trait::HasTable'],
      },
  );

  sub has_table {
      my $meta = shift;
      $meta->table(shift);
  }

  package MyApp::Meta::Class::Trait::HasTable;
  use Moose::Role;

  has table => (
      is  => 'rw',
      isa => 'Str',
  );
}



# =begin testing
{
{
    package MyApp::User;

    use Moose;
    MyApp::Mooseish->import;

    has_table( 'User' );

    has( 'username' => ( is => 'ro' ) );
    has( 'password' => ( is => 'ro' ) );

    sub login { }
}

can_ok( MyApp::User->meta, 'table' );
is( MyApp::User->meta->table, 'User',
    'MyApp::User->meta->table returns User' );
ok( MyApp::User->can('username'),
    'MyApp::User has username method' );
}




1;
