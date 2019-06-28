# extra-option: let perl_sub_signatures=1

use strict;
use warnings;
use experimental 'signatures';

sub aaa : prototype($$) ($a, $b) {
    return;
}
