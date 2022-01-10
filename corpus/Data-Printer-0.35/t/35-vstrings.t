use strict;
use warnings;

BEGIN {
    $ENV{ANSI_COLORS_DISABLED} = 1;
    delete $ENV{DATAPRINTERRC};
    use File::HomeDir::Test;  # avoid user's .dataprinter

    use Test::More;
    use Data::Printer;

}

plan skip_all => 'Older perls do not have VSTRING support' if $] < 5.010;
my $scalar = v1.2.3;
eval {
    is( p($scalar), 'v1.2.3', "VSTRINGs" );
};
if ($@) {
    fail( "VSTRINGs" );
    diag( $@ );
}

done_testing();
