#!/usr/bin/perl -w

use strict;
use Test::More 'no_plan';
use Test::Fatal;
$| = 1;



# =begin testing SETUP
BEGIN {
  package MyApp::Meta::Class::Trait::HasTable;
  use Moose::Role;
  Moose::Util::meta_class_alias('HasTable');

  has table => (
      is  => 'rw',
      isa => 'Str',
  );
}



# =begin testing SETUP
{

  # in lib/MyApp/Meta/Class/Trait/HasTable.pm
  package MyApp::Meta::Class::Trait::HasTable;
  use Moose::Role;
  Moose::Util::meta_class_alias('HasTable');

  has table => (
      is  => 'rw',
      isa => 'Str',
  );

  # in lib/MyApp/User.pm
  package MyApp::User;
  use Moose -traits => 'HasTable';

  __PACKAGE__->meta->table('User');
}



# =begin testing
{
can_ok( MyApp::User->meta, 'table' );
is( MyApp::User->meta->table, 'User', 'My::User table is User' );
}




1;
