use strict;
use warnings;

BEGIN {
    $ENV{ANSI_COLORS_DISABLED} = 1;
    delete $ENV{DATAPRINTERRC};
    use File::HomeDir::Test;  # avoid user's .dataprinter

    use Test::More;
    use Data::Printer;

}

format TEST =
.

my $form = *TEST{FORMAT};
my $test_name = "FORMAT refs";
eval {
    is( p($form), 'FORMAT', $test_name );
};
if ($@) {
    fail( $test_name );
    diag( $@ );
}

done_testing();
