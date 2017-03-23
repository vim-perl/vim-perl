use strict;
use warnings;

use Test::More;
BEGIN {
    $ENV{ANSI_COLORS_DISABLED} = 1;
    delete $ENV{DATAPRINTERRC};
    use File::HomeDir::Test;  # avoid user's .dataprinter
};

use Data::Printer return_value => 'void';

eval { require Capture::Tiny; 1; }
    or plan skip_all => 'Capture::Tiny not found';

my $string = 'All your base are belong to us.';
my $expected = qq{"$string"$/};

my $return = 1;
my ($stdout, $stderr) = Capture::Tiny::capture( sub {
    $return = p $string;
});

is $stdout, '', 'STDOUT should be empty after p() (scalar, scalar)';
is $stderr, $expected, 'pass-through STDERR (scalar, scalar)';

is $return, undef, 'pass-through return (scalar scalar)';

done_testing;
