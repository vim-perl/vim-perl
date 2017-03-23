use strict;
use warnings;
use Test::More;
BEGIN {
    $ENV{ANSI_COLORS_DISABLED} = 1;
    delete $ENV{DATAPRINTERRC};
    use File::HomeDir::Test;  # avoid user's .dataprinter
};

use Data::Printer return_value => 'void';

use Fcntl;
use File::Temp    qw( :seekable tempfile );

eval { require Capture::Tiny; 1; }
    or plan skip_all => 'Capture::Tiny not found';
;

#=====================
# testing OUTPUT
#=====================
my $item = 42;

my ($stdout, $stderr) = Capture::Tiny::capture( sub {
     p $item, output => *STDOUT;
});

is $stdout, $item . $/, 'redirected output to STDOUT';
is $stderr, '',         'redirecting to STDOUT leaves STDERR empty';


#=====================
# testing OUTPUT ref
#=====================
$item++; # just to make sure there won't be any sort of cache

($stdout, $stderr) = Capture::Tiny::capture( sub {
     p $item, output => \*STDOUT;
});

is $stdout, $item . $/, 'redirected output to a STDOUT ref';
is $stderr, '',         'redirecting to STDOUT ref leaves STDERR empty';


#=====================
# testing scalar ref
#=====================
$item++;

my $destination;
($stdout, $stderr) = Capture::Tiny::capture( sub {
     p $item, output => \$destination;
});

is $destination, $item . $/, 'redirected output to a scalar ref';
is $stdout, '',              'redirecting to scalar ref leaver STDOUT empty';
is $stderr, '',              'redirecting to scalar ref leaves STDERR empty';


#=====================
# testing file handle
#=====================
$item++;


my $fh = tempfile;
($stdout, $stderr) = Capture::Tiny::capture( sub {
     p $item, output => $fh;
});

seek( $fh, 0, SEEK_SET );
my $buffer = do { local $/; <$fh> };

is $buffer, $item . $/, 'redirected output to a file handle';
is $stdout, '',         'redirecting to file handle leaves STDOUT empty';
is $stderr, '',         'redirecting to file handle leaves STDERR empty';


done_testing;
