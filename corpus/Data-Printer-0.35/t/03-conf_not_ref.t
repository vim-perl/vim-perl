use strict;
use warnings;

use Test::More;
BEGIN {
    $ENV{ANSI_COLORS_DISABLED} = 1;
    delete $ENV{DATAPRINTERRC};
    use File::HomeDir::Test;  # avoid user's .dataprinter
};

use Data::Printer
    'name'           => 'TEST',
    'indent'         => 2,
    'index'          => 0,
    'hash_separator' => ' => ',
    'max_depth'      => 2,
;

my $data = [ 1, 2, { foo => 3, bar => { 1 => 2}, baz => [0, 1]  } ];
push @$data, $data->[2];

is( p($data), '\\ [
  1,
  2,
  {
    bar => { ... },
    baz => [ ... ],
    foo => 3
  },
  TEST[2]
]', 'customization' );

done_testing;
