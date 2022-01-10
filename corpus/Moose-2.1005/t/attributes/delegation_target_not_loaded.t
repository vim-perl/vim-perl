use strict;
use warnings;

use Test::More;
use Test::Fatal;

{
    package X;

    use Moose;

    ::like(
        ::exception{ has foo => (
                is      => 'ro',
                isa     => 'Foo',
                handles => qr/.*/,
            )
            },
        qr/\QThe foo attribute is trying to delegate to a class which has not been loaded - Foo/,
        'cannot delegate to a class which is not yet loaded'
    );

    ::like(
        ::exception{ has foo => (
                is      => 'ro',
                does    => 'Role::Foo',
                handles => qr/.*/,
            )
            },
        qr/\QThe foo attribute is trying to delegate to a role which has not been loaded - Role::Foo/,
        'cannot delegate to a role which is not yet loaded'
    );
}

done_testing;
