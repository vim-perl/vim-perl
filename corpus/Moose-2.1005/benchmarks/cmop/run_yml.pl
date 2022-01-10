#!/usr/bin/perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/lib";

use YAML::Syck;
use Bench::Run;

my $data = LoadFile( shift || "$FindBin::Bin/all.yml" );

foreach my $bench ( @$data ) {
    print "== ", delete $bench->{name}, " ==\n\n";
    Bench::Run->new( %$bench )->run;
    print "\n\n";
}


