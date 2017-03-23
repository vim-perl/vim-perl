use strict;
use warnings;

use Test::More;
use Test::Moose;

{
    package Foo;
    use Moose;
    has 'type' => (
        required => 0,
        reader   => 'get_type',
        default  => 1,
    );

    # Assigning types to these non-alpha attrs exposed a bug in Moose.
    has '@type' => (
        isa      => 'Str',
        required => 0,
        reader   => 'get_at_type',
        writer   => 'set_at_type',
        default  => 'at type',
    );

    has 'has spaces' => (
        isa      => 'Int',
        required => 0,
        reader   => 'get_hs',
        default  => 42,
    );

    has '!req' => (
        required => 1,
        reader   => 'req'
    );

    no Moose;
}

with_immutable {
    ok( Foo->meta->has_attribute($_), "Foo has '$_' attribute" )
        for 'type', '@type', 'has spaces';

    my $foo = Foo->new( '!req' => 42 );

    is( $foo->get_type,    1,         q{'type' attribute default is 1} );
    is( $foo->get_at_type, 'at type', q{'@type' attribute default is 1} );
    is( $foo->get_hs, 42, q{'has spaces' attribute default is 42} );

    $foo = Foo->new(
        type         => 'foo',
        '@type'      => 'bar',
        'has spaces' => 200,
        '!req'       => 84,
    );

    isa_ok( $foo, 'Foo' );
    is( $foo->get_at_type, 'bar', q{reader for '@type'} );
    is( $foo->get_hs,      200, q{reader for 'has spaces'} );

    $foo->set_at_type(99);
    is( $foo->get_at_type, 99, q{writer for '@type' worked} );
}
'Foo';

done_testing;
