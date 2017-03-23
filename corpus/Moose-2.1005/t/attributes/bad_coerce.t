use strict;
use warnings;

use Test::More;

use Test::Requires {
    'Test::Output' => '0.01', # skip all if not installed
};

{
    package Foo;

    use Moose;

    ::stderr_like{ has foo => (
            is     => 'ro',
            isa    => 'Str',
            coerce => 1,
        );
        }
        qr/\QYou cannot coerce an attribute (foo) unless its type (Str) has a coercion/,
        'Cannot coerce unless the type has a coercion';

    ::stderr_like{ has bar => (
            is     => 'ro',
            isa    => 'Str',
            coerce => 1,
        );
        }
        qr/\QYou cannot coerce an attribute (bar) unless its type (Str) has a coercion/,
        'Cannot coerce unless the type has a coercion - different attribute';
}

done_testing;
