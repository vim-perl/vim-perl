use strict;
use warnings;
use Test::More;

BEGIN {
    delete $ENV{ANSI_COLORS_DISABLED};
    delete $ENV{DATAPRINTERRC};
    use File::HomeDir::Test;  # avoid user's .dataprinter
    use_ok ('Term::ANSIColor');
    use_ok ('Data::Printer', colored => 1);
};

my $number = 3.14;
is( p($number), color('reset') . colored($number, 'bright_blue'), 'colored number');

my $string = 'test';
is( p($string), color('reset') . q["] . colored('test', 'bright_yellow') . q["], 'colored string');

my $undef = undef;
is( p($undef), color('reset') . colored('undef', 'bright_red'), 'colored undef');

my $regex = qr{1};
is( p($regex), color('reset') . '\\ ' . colored('1', 'yellow'), 'colored regex');

my $code = sub {};
is( p($code), color('reset') . '\\ ' . colored('sub { ... }', 'green'), 'colored code');

my @array = (1);
is( p(@array), color('reset') . "[$/    "
               . colored('[0] ', 'bright_white')
               . colored(1, 'bright_blue')
               . "$/]"
, 'colored array');

my %hash = (1=>2);
is( p(%hash), color('reset') . "{$/    "
              . colored(1, 'magenta')
              . '   '
              . colored(2, 'bright_blue')
              . "$/}"
, 'colored hash');

my $circular = [];
$circular->[0] = $circular;
is( p($circular), color('reset') . "\\ [$/    "
                  . colored('[0] ', 'bright_white')
                  . colored('var', 'white on_red')
                  . "$/]"
, 'colored circular ref');


# testing 'colored' property
is( p($number, colored => 0), $number, 'uncolored number');


done_testing;
