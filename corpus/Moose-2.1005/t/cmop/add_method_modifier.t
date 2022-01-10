use strict;
use warnings;

use Test::More;
use Test::Fatal;

use Class::MOP;

{

    package BankAccount;

    use strict;
    use warnings;
    use metaclass;

    use Carp 'confess';

    BankAccount->meta->add_attribute(
        'balance' => (
            accessor => 'balance',
            init_arg => 'balance',
            default  => 0
        )
    );

    sub new { (shift)->meta->new_object(@_) }

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

    use strict;
    use warnings;
    use metaclass;

    use base 'BankAccount';

    CheckingAccount->meta->add_attribute(
        'overdraft_account' => (
            accessor => 'overdraft_account',
            init_arg => 'overdraft',
        )
    );

    CheckingAccount->meta->add_before_method_modifier(
        'withdraw' => sub {
            my ( $self, $amount ) = @_;
            my $overdraft_amount = $amount - $self->balance();
            if ( $overdraft_amount > 0 ) {
                $self->overdraft_account->withdraw($overdraft_amount);
                $self->deposit($overdraft_amount);
            }
        }
    );

    ::like(
        ::exception{ CheckingAccount->meta->add_before_method_modifier(
                'does_not_exist' => sub { }
            );
            },
        qr/\QThe method 'does_not_exist' was not found in the inheritance hierarchy for CheckingAccount/
    );

    ::ok( CheckingAccount->meta->has_method('withdraw'),
        '... checking account now has a withdraw method' );
    ::isa_ok( CheckingAccount->meta->get_method('withdraw'),
        'Class::MOP::Method::Wrapped' );
    ::isa_ok( BankAccount->meta->get_method('withdraw'),
        'Class::MOP::Method' );

    CheckingAccount->meta->add_method( foo => sub { 'foo' } );
    CheckingAccount->meta->add_before_method_modifier( foo => sub { 'wrapped' } );
    ::isa_ok( CheckingAccount->meta->get_method('foo'),
        'Class::MOP::Method::Wrapped' );
}

my $savings_account = BankAccount->new( balance => 250 );
isa_ok( $savings_account, 'BankAccount' );

is( $savings_account->balance, 250, '... got the right savings balance' );
is( exception {
    $savings_account->withdraw(50);
}, undef, '... withdrew from savings successfully' );
is( $savings_account->balance, 200,
    '... got the right savings balance after withdrawal' );
isnt( exception {
    $savings_account->withdraw(250);
}, undef, '... could not withdraw from savings successfully' );

$savings_account->deposit(150);
is( $savings_account->balance, 350,
    '... got the right savings balance after deposit' );

my $checking_account = CheckingAccount->new(
    balance   => 100,
    overdraft => $savings_account
);
isa_ok( $checking_account, 'CheckingAccount' );
isa_ok( $checking_account, 'BankAccount' );

is( $checking_account->overdraft_account, $savings_account,
    '... got the right overdraft account' );

is( $checking_account->balance, 100, '... got the right checkings balance' );

is( exception {
    $checking_account->withdraw(50);
}, undef, '... withdrew from checking successfully' );
is( $checking_account->balance, 50,
    '... got the right checkings balance after withdrawal' );
is( $savings_account->balance, 350,
    '... got the right savings balance after checking withdrawal (no overdraft)'
);

is( exception {
    $checking_account->withdraw(200);
}, undef, '... withdrew from checking successfully' );
is( $checking_account->balance, 0,
    '... got the right checkings balance after withdrawal' );
is( $savings_account->balance, 200,
    '... got the right savings balance after overdraft withdrawal' );

done_testing;
