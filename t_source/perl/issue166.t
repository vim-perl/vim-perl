# extra-option: let perl_sub_signatures=1

use strict;
use warnings;
use experimental 'signatures';

sub add($x, $y) {
    return $x + $y;
}

sub subtract($x, $y) {
    return $x - $y;
}
