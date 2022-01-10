use strict;
use warnings;

use Test::More;
BEGIN {
    $ENV{ANSI_COLORS_DISABLED} = 1;
    delete $ENV{DATAPRINTERRC};
    use File::HomeDir::Test;  # avoid user's .dataprinter
};

use Data::Printer use_prototypes => 0;

is p(\"test"), '"test"', 'scalar without prototype check';

is p( { foo => 42 } ),
'{
    foo   42
}', 'hash without prototype check';

is p( [ 1, 2 ] ),
'[
    [0] 1,
    [1] 2
]', 'array without prototype check';


done_testing;
