#!perl -w
use strict;
use Benchmark qw(:all);

my ( $count, $module ) = @ARGV;
$count  ||= 10;
$module ||= 'Moose';

my @blib
    = qw(-Iblib/lib -Iblib/arch -I../Moose/blib/lib -I../Moose/blib/arch -I../Moose/lib);

$| = 1;    # autoflush

print 'Installed: ';
system $^X, '-le', 'require Moose; print $INC{q{Moose.pm}}';

print 'Blead:     ';
system $^X, @blib, '-le', 'require Moose; print $INC{q{Moose.pm}}';

cmpthese timethese $count => {
    released => sub {
        system( $^X, '-e', "require $module" ) == 0 or die;
    },
    blead => sub {
        system( $^X, @blib, '-e', "require $module" ) == 0 or die;
    },
};
