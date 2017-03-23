#!/usr/bin/perl -w

use strict;
use Test::More 'no_plan';
use Test::Fatal;
$| = 1;



# =begin testing SETUP
{

  package MyApp::Meta::Method::PrivateOrPublic;

  use Moose;
  use Moose::Util::TypeConstraints;

  extends 'Moose::Meta::Method';

  has '_policy' => (
      is       => 'ro',
      isa      => enum( [ qw( public private ) ] ),
      default  => 'public',
      init_arg => 'policy',
  );

  sub new {
      my $class   = shift;
      my %options = @_;

      my $self = $class->SUPER::wrap(%options);

      $self->{_policy} = $options{policy};

      $self->_add_policy_wrapper;

      return $self;
  }

  sub _add_policy_wrapper {
      my $self = shift;

      return if $self->is_public;

      my $name      = $self->name;
      my $package   = $self->package_name;
      my $real_body = $self->body;

      my $body = sub {
          die "The $package\::$name method is private"
              unless ( scalar caller() ) eq $package;

          goto &{$real_body};
      };

      $self->{body} = $body;
  }

  sub is_public  { $_[0]->_policy eq 'public' }
  sub is_private { $_[0]->_policy eq 'private' }

  package MyApp::User;

  use Moose;

  has 'password' => ( is => 'rw' );

  __PACKAGE__->meta()->add_method(
      '_reset_password',
      MyApp::Meta::Method::PrivateOrPublic->new(
          name         => '_reset_password',
          package_name => __PACKAGE__,
          body         => sub { $_[0]->password('reset') },
          policy       => 'private',
      )
  );
}



# =begin testing
{
package main;

use Test::Fatal;

my $user = MyApp::User->new( password => 'foo!' );

like( exception { $user->_reset_password },
qr/The MyApp::User::_reset_password method is private/,
    '_reset_password method dies if called outside MyApp::User class');

{
    package MyApp::User;

    sub run_reset { $_[0]->_reset_password }
}

$user->run_reset;

is( $user->password, 'reset', 'password has been reset' );
}




1;
