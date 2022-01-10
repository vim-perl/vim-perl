#!perl -T
use strict;
use warnings;
use Test::More;
use Scalar::Util qw(tainted);

my $path;

BEGIN {
    # we only catch 1 char to avoid leaking
    # user information on test results
    $path = substr $ENV{PATH}, 0, 1;
    plan skip_all => 'tainted sample not found. Skipping...'
        unless tainted($path);

    delete $ENV{ANSI_COLORS_DISABLED};
    delete $ENV{DATAPRINTERRC};
    use File::HomeDir::Test;  # avoid user's .dataprinter
    use_ok ('Term::ANSIColor');
    use_ok ('Data::Printer', colored => 1);
};

is(
    p($path),
    color('reset') . q["] . colored($path, 'bright_yellow') . q["]
                   . ' ' . colored('(TAINTED)', 'red'),
    'tainted scalar'
);


done_testing;
