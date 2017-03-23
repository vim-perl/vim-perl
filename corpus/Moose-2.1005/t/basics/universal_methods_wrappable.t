use strict;
use warnings;

use Test::Fatal;
use Test::More;

{

    package FakeBar;
    use Moose::Role;

    around isa => sub {
        my ( $orig, $self, $v ) = @_;
        return 1 if $v eq 'Bar';
        return $orig->( $self, $v );
    };

    package Foo;
    use Moose;

    use Test::More;

    ::is( ::exception { with 'FakeBar' }, undef, 'applied role' );

    my $foo = Foo->new;
    ::isa_ok( $foo, 'Bar' );
}

done_testing;
