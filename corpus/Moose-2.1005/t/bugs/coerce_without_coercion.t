use strict;
use warnings;

use Test::More;
use Test::Fatal;
use Test::Moose;

{
    package Foo;

    use Moose::Deprecated -api_version => '1.07';
    use Moose;

    has x => (
        is     => 'rw',
        isa    => 'HashRef',
        coerce => 1,
    );
}

with_immutable {
    is( exception { Foo->new( x => {} ) }, undef, 'Setting coerce => 1 without a coercion on the type does not cause an error in the constructor' );

    is( exception { Foo->new->x( {} ) }, undef, 'Setting coerce => 1 without a coercion on the type does not cause an error when setting the attribut' );

    like( exception { Foo->new( x => 42 ) }, qr/\QAttribute (x) does not pass the type constraint because/, 'Attempting to provide an invalid value to the constructor for this attr still fails' );

    like( exception { Foo->new->x(42) }, qr/\QAttribute (x) does not pass the type constraint because/, 'Attempting to provide an invalid value to the accessor for this attr still fails' );
}
'Foo';

done_testing;
