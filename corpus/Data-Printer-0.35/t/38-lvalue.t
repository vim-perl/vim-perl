use strict;
use warnings;

BEGIN {
    $ENV{ANSI_COLORS_DISABLED} = 1;
    delete $ENV{DATAPRINTERRC};
    use File::HomeDir::Test;  # avoid user's .dataprinter

    use Test::More;
    use Data::Printer;

}

my $scalar = \substr( "abc", 2);
my $test_name = "LVALUE refs";
eval {
    is( p($scalar), '"c" (LVALUE)', $test_name );
    is( p($scalar, show_lvalue => 0), '"c"', 'disabled ' . $test_name );
};
if ($@) {
    fail( $test_name );
    diag( $@ );
}

done_testing();
