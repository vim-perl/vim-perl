# making sure data is properly aligned
use strict;
use warnings;

use Test::More tests => 1;

BEGIN {
    $ENV{ANSI_COLORS_DISABLED} = 1;
    delete $ENV{DATAPRINTERRC};
    use File::HomeDir::Test;  # avoid user's .dataprinter
    use Data::Printer;
};

my $var = { q[foo bar],2,3,4};

is(
   p($var),
q{\ {
    3           4,
    'foo bar'   2
}},
  'colored alignment'
);


