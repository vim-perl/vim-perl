use strict;
use warnings;

use Test::More;
use Test::Fatal;

use Carp;

$SIG{__WARN__} = \&croak;

pass("nothing for now...");

done_testing;
