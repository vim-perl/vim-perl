use strict;
use warnings;

BEGIN {
    delete $ENV{DATAPRINTERRC};
    use File::HomeDir::Test;  # avoid user's .dataprinter
    use Term::ANSIColor;
};

use Test::More;
use Data::Printer caller_info => 1;

sub _get_path { my (undef, $filename) =caller; return $filename }
my $filepath = _get_path();

my $var = [ 1, { foo => 'bar' } ];
is p($var), "Printing in line " . __LINE__ . " of $filepath:
\\ [
    [0] 1,
    [1] {
        foo   \"bar\"
    }
]", 'output with caller info';

$var = 3; # simplify output
is p($var, caller_message => 'also, a __PACKAGE__'),
   'also, a main
3', 'output with custom caller message';

is p($var, colored => 1), color('reset')
 . colored("Printing in line " . (__LINE__ - 1) . " of $filepath:", 'bright_cyan')
 . "\n" . colored($var, 'bright_blue')
 , 'colored caller message';

is p( $var, colored => 1, color => { caller_info => 'red' } ), color('reset')
 . colored("Printing in line " . (__LINE__ - 1) . " of $filepath:", 'red')
 . "\n" . colored($var, 'bright_blue')
 , 'custom colored caller message';


done_testing;
