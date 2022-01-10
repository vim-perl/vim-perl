use strict;
use warnings;

use Test::More tests => 3;
BEGIN {
    $ENV{ANSI_COLORS_DISABLED} = 1;
    delete $ENV{DATAPRINTERRC};
    use File::HomeDir::Test;  # avoid user's .dataprinter
};

use Data::Printer separator => '--';

my $structure = [
    1,
    2,
    {
        a          => 1,
        b          => 2,
        long_line  => 3,
    },
];

my $end_comma_output = '\ [
    [0] 1--
    [1] 2--
    [2] {
        a           1--
        b           2--
        long_line   3
    }
]';

is(
    p($structure),
    $end_comma_output,
    "Got correct structure with separator => '--'",
);

$end_comma_output = '\ [
    [0] 1
    [1] 2
    [2] {
        a           1
        b           2
        long_line   3
    }
]';

is(
    p($structure, separator => ''),
    $end_comma_output,
    "Got correct structure with no separator",
);

is(
    p($structure, separator => '', end_separator => 1),
    $end_comma_output,
    "Got correct structure with no separator, even with end_separator set to 1",
);
