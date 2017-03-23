use strict;
use warnings;

BEGIN {
    $ENV{ANSI_COLORS_DISABLED} = 1;
    delete $ENV{DATAPRINTERRC};
    use File::HomeDir::Test;  # avoid user's .dataprinter

    use Test::More;
    use_ok( 'DDP', filters => { SCALAR => sub { '...' } } ) or plan skip_all => 'unable to load DDP';
}

my $scalar = 'test';
is( p($scalar), '...', 'simple filtered scalar' );

my %hash = (
    foo => 33,
    bar => 'moo',
    test => \$scalar,
    hash => { 1 => 2, 3 => { 4 => 5 }, 10 => 11 },
    something => [ 3 .. 5 ],
);

is( p(%hash),
'{
    bar         ...,
    foo         ...,
    hash        {
        1    ...,
        3    {
            4   ...
        },
        10   ...
    },
    something   [
        [0] ...,
        [1] ...,
        [2] ...
    ],
    test        \\ ...
}', 'nested hash');



done_testing;
