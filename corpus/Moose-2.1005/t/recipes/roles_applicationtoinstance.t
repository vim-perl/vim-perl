#!/usr/bin/perl -w

use strict;
use Test::More 'no_plan';
use Test::Fatal;
$| = 1;



# =begin testing SETUP
{
    # Not in the recipe, but needed for writing tests.
    package Employee;

    use Moose;

    has 'name' => (
        is       => 'ro',
        isa      => 'Str',
        required => 1,
    );

    has 'work' => (
        is        => 'rw',
        isa       => 'Str',
        predicate => 'has_work',
    );
}



# =begin testing SETUP
{

  package MyApp::Role::Job::Manager;

  use List::Util qw( first );

  use Moose::Role;

  has 'employees' => (
      is  => 'rw',
      isa => 'ArrayRef[Employee]',
  );

  sub assign_work {
      my $self = shift;
      my $work = shift;

      my $employee = first { !$_->has_work } @{ $self->employees };

      die 'All my employees have work to do!' unless $employee;

      $employee->work($work);
  }

  package main;

  my $lisa = Employee->new( name => 'Lisa' );
  MyApp::Role::Job::Manager->meta->apply($lisa);

  my $homer = Employee->new( name => 'Homer' );
  my $bart  = Employee->new( name => 'Bart' );
  my $marge = Employee->new( name => 'Marge' );

  $lisa->employees( [ $homer, $bart, $marge ] );
  $lisa->assign_work('mow the lawn');
}



# =begin testing
{
{
    my $lisa = Employee->new( name => 'Lisa' );
    MyApp::Role::Job::Manager->meta->apply($lisa);

    my $homer = Employee->new( name => 'Homer' );
    my $bart  = Employee->new( name => 'Bart' );
    my $marge = Employee->new( name => 'Marge' );

    $lisa->employees( [ $homer, $bart, $marge ] );
    $lisa->assign_work('mow the lawn');

    ok( $lisa->does('MyApp::Role::Job::Manager'),
        'lisa now does the manager role' );

    is( $homer->work, 'mow the lawn',
        'homer was assigned a task by lisa' );
}
}




1;
