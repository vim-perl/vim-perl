use strict;
use warnings;

use Test::More;
BEGIN {
    $ENV{ANSI_COLORS_DISABLED} = 1;
    delete $ENV{DATAPRINTERRC};
    use File::HomeDir::Test;  # avoid user's .dataprinter
};

eval 'use Data::Printer 0.1';
ok !$@, 'could load with version number';

eval 'use Data::Printer qw(meep)';
like $@, qr/either a hash/, 'croaked with proper error message';

done_testing;
