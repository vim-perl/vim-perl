#!perl

use Test::More tests => 1;

BEGIN {
    diag( "Beginning Data::Printer tests in $^O with Perl $], $^X" );
    use_ok( 'Data::Printer' ) || print "Bail out!
";
}

diag( "Testing Data::Printer $Data::Printer::VERSION" );
