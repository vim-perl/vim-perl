use strict;
use warnings;

use Test::More tests => 1;
BEGIN {
    $ENV{ANSI_COLORS_DISABLED} = 1;
    delete $ENV{DATAPRINTERRC};
    use File::HomeDir::Test;  # avoid user's .dataprinter
};

use Data::Printer end_separator => 1, separator => '--';

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
        long_line   3--
    }--
]';

is(
    p($structure),
    $end_comma_output,
    "Got correct structure with end_separator => 1 and separator => '--'",
);

