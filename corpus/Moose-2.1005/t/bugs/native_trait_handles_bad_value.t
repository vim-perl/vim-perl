use strict;
use warnings;

use Test::More;
use Test::Fatal;

{

    package Bug;
    use Moose;

    ::like(
        ::exception{ has member => (
                is      => 'ro',
                isa     => 'HashRef',
                traits  => ['Hash'],
                handles => {
                    method => sub { }
                },
            );
            },
        qr/\QAll values passed to handles must be strings or ARRAY references, not CODE/,
        'bad value in handles throws a useful error'
    );
}

done_testing;
