#!/usr/bin/perl -w

use strict;
use Test::More 'no_plan';
use Test::Fatal;
$| = 1;



# =begin testing SETUP
{

  package BankAccount;
  use Moose;

  has 'balance' => ( isa => 'Int', is => 'rw', default => 0 );

  sub deposit {
      my ( $self, $amount ) = @_;
      $self->balance( $self->balance + $amount );
  }

  sub withdraw {
      my ( $self, $amount ) = @_;
      my $current_balance = $self->balance();
      ( $current_balance >= $amount )
          || confess "Account overdrawn";
      $self->balance( $current_balance - $amount );
  }

  package CheckingAccount;
  use Moose;

  extends 'BankAccount';

  has 'overdraft_account' => ( isa => 'BankAccount', is => 'rw' );

  before 'withdraw' => sub {
      my ( $self, $amount ) = @_;
      my $overdraft_amount = $amount - $self->balance();
      if ( $self->overdraft_account && $overdraft_amount > 0 ) {
          $self->overdraft_account->withdraw($overdraft_amount);
          $self->deposit($overdraft_amount);
      }
  };
}



# =begin testing
{
my $savings_account;

{
    $savings_account = BankAccount->new( balance => 250 );
    isa_ok( $savings_account, 'BankAccount' );

    is( $savings_account->balance, 250, '... got the right savings balance' );
    is(
        exception {
            $savings_account->withdraw(50);
        },
        undef,
        '... withdrew from savings successfully'
    );
    is( $savings_account->balance, 200,
        '... got the right savings balance after withdrawal' );

    $savings_account->deposit(150);
    is( $savings_account->balance, 350,
        '... got the right savings balance after deposit' );
}

{
    my $checking_account = CheckingAccount->new(
        balance           => 100,
        overdraft_account => $savings_account
    );
    isa_ok( $checking_account, 'CheckingAccount' );
    isa_ok( $checking_account, 'BankAccount' );

    is( $checking_account->overdraft_account, $savings_account,
        '... got the right overdraft account' );

    is( $checking_account->balance, 100,
        '... got the right checkings balance' );

    is(
        exception {
            $checking_account->withdraw(50);
        },
        undef,
        '... withdrew from checking successfully'
    );
    is( $checking_account->balance, 50,
        '... got the right checkings balance after withdrawal' );
    is( $savings_account->balance, 350,
        '... got the right savings balance after checking withdrawal (no overdraft)'
    );

    is(
        exception {
            $checking_account->withdraw(200);
        },
        undef,
        '... withdrew from checking successfully'
    );
    is( $checking_account->balance, 0,
        '... got the right checkings balance after withdrawal' );
    is( $savings_account->balance, 200,
        '... got the right savings balance after overdraft withdrawal' );
}

{
    my $checking_account = CheckingAccount->new(
        balance => 100

            # no overdraft account
    );
    isa_ok( $checking_account, 'CheckingAccount' );
    isa_ok( $checking_account, 'BankAccount' );

    is( $checking_account->overdraft_account, undef,
        '... no overdraft account' );

    is( $checking_account->balance, 100,
        '... got the right checkings balance' );

    is(
        exception {
            $checking_account->withdraw(50);
        },
        undef,
        '... withdrew from checking successfully'
    );
    is( $checking_account->balance, 50,
        '... got the right checkings balance after withdrawal' );

    isnt(
        exception {
            $checking_account->withdraw(200);
        },
        undef,
        '... withdrawal failed due to attempted overdraft'
    );
    is( $checking_account->balance, 50,
        '... got the right checkings balance after withdrawal failure' );
}
}




1;
