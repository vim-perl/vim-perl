use strict;
use warnings;

use Test::More;
BEGIN {
    $ENV{ANSI_COLORS_DISABLED} = 1;
    delete $ENV{DATAPRINTERRC};
    use File::HomeDir::Test;  # avoid user's .dataprinter
};

use Data::Printer {
    'multiline' => 0,
};

my $data = [ 1, 2, { foo => 3, bar => 4 } ];
push @$data, $data->[2];

is( p($data), '\\ [ 1, 2, { bar   4, foo   3 }, var[2] ]', 'single-line dump' );

done_testing;
