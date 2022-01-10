######################################
######## EXPERIMENTAL FEATURE ########
######################################
use strict;
use warnings;

use Test::More tests => 1;
BEGIN {
    $ENV{ANSI_COLORS_DISABLED} = 1;
    delete $ENV{DATAPRINTERRC};
    use File::HomeDir::Test;  # avoid user's .dataprinter
};

use Data::Printer show_readonly => 1;

my $foo = 42;

&Internals::SvREADONLY( \$foo, 1 );

is p($foo), '42 (read-only)', 'readonly variables (experimental)';
