# extra-option: let perl_sub_signatures=1

use strict;
use warnings;
use experimental 'signatures';

sub asas::asdsad::adsa : prototype() : lvalue : method ($d) {    # adasdsad
    return;
}

sub asdsad : prototype() : lvalue
  : method($d) {                                                 # adasdsad
    my $s = sub : prototype($$) ( $a, $v ) {
        return;
    };

    return;
}
