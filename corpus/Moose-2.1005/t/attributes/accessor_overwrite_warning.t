use strict;
use warnings;

use Test::More;

use Test::Requires {
    'Test::Output' => '0.01',
};

{
    package Bar;
    use Moose;

    has has_attr => (
        is => 'ro',
    );

    ::stderr_like{ has attr => (
            is        => 'ro',
            predicate => 'has_attr',
        )
        }
        qr/\QYou are overwriting an accessor (has_attr) for the has_attr attribute with a new accessor method for the attr attribute/,
        'overwriting an accessor for another attribute causes a warning';
}

done_testing;
