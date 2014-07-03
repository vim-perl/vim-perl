# extra-option: let perl_no_subprototype_error=1

use strict;
use warnings;
use experimental 'signatures';

sub add($x, $y) {
    return $x + $y;
}

sub subtract($x, $y) {
    return $x - $y;
}
