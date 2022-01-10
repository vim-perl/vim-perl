#!/usr/bin/perl -w

use strict;
use Test::More 'no_plan';
use Test::Fatal;
$| = 1;



# =begin testing SETUP
{
    package My::Meta::Instance;
    use Moose;

    # This needs to be in a BEGIN block so to avoid a metaclass
    # incompatibility error from Moose. In normal usage,
    # My::Meta::Instance would be in a separate file from MyApp::User,
    # and this would be a non-issue.
    BEGIN { extends 'Moose::Meta::Instance' }
}



# =begin testing SETUP
{

  package My::Meta::Instance;

  use Scalar::Util qw( weaken );
  use Symbol qw( gensym );

  use Moose;
  extends 'Moose::Meta::Instance';

  sub create_instance {
      my $self = shift;
      my $sym = gensym();
      bless $sym, $self->_class_name;
  }

  sub clone_instance {
      my ( $self, $instance ) = @_;

      my $new_sym = gensym();
      %{*$new_sym} = %{*$instance};

      bless $new_sym, $self->_class_name;
  }

  sub get_slot_value {
      my ( $self, $instance, $slot_name ) = @_;
      return *$instance->{$slot_name};
  }

  sub set_slot_value {
      my ( $self, $instance, $slot_name, $value ) = @_;
      *$instance->{$slot_name} = $value;
  }

  sub deinitialize_slot {
      my ( $self, $instance, $slot_name ) = @_;
      delete *$instance->{$slot_name};
  }

  sub is_slot_initialized {
      my ( $self, $instance, $slot_name ) = @_;
      exists *$instance->{$slot_name};
  }

  sub weaken_slot_value {
      my ( $self, $instance, $slot_name ) = @_;
      weaken *$instance->{$slot_name};
  }

  sub inline_create_instance {
      my ( $self, $class_variable ) = @_;
      return 'do { my $sym = Symbol::gensym(); bless $sym, ' . $class_variable . ' }';
  }

  sub inline_slot_access {
      my ( $self, $instance, $slot_name ) = @_;
      return '*{' . $instance . '}->{' . $slot_name . '}';
  }

  package MyApp::User;

  use metaclass 'Moose::Meta::Class' =>
      ( instance_metaclass => 'My::Meta::Instance' );

  use Moose;

  has 'name' => (
      is  => 'rw',
      isa => 'Str',
  );

  has 'email' => (
      is  => 'rw',
      isa => 'Str',
  );
}



# =begin testing
{
{
    package MyApp::Employee;

    use Moose;
    extends 'MyApp::User';

    has 'employee_number' => ( is => 'rw' );
}

for my $x ( 0 .. 1 ) {
    MyApp::User->meta->make_immutable if $x;

    my $user = MyApp::User->new(
        name  => 'Faye',
        email => 'faye@example.com',
    );

    ok( eval { *{$user} }, 'user object is an glob ref with some values' );

    is( $user->name,  'Faye',             'check name' );
    is( $user->email, 'faye@example.com', 'check email' );

    $user->name('Ralph');
    is( $user->name, 'Ralph', 'check name after changing it' );

    $user->email('ralph@example.com');
    is( $user->email, 'ralph@example.com', 'check email after changing it' );
}

for my $x ( 0 .. 1 ) {
    MyApp::Employee->meta->make_immutable if $x;

    my $emp = MyApp::Employee->new(
        name            => 'Faye',
        email           => 'faye@example.com',
        employee_number => $x,
    );

    ok( eval { *{$emp} }, 'employee object is an glob ref with some values' );

    is( $emp->name,            'Faye',             'check name' );
    is( $emp->email,           'faye@example.com', 'check email' );
    is( $emp->employee_number, $x,                 'check employee_number' );

    $emp->name('Ralph');
    is( $emp->name, 'Ralph', 'check name after changing it' );

    $emp->email('ralph@example.com');
    is( $emp->email, 'ralph@example.com', 'check email after changing it' );

    $emp->employee_number(42);
    is( $emp->employee_number, 42, 'check employee_number after changing it' );
}
}




1;
