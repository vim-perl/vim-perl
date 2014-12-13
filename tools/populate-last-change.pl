#!/usr/bin/env perl

use strict;
use warnings;
use feature qw(say);

use DateTime;

my ( $input ) = @ARGV;

sub last_change_for_file {
    my ( $filename ) = @_;

    my $epoch = qx(git log -1 --format=format:%at -- $filename);
    chomp $epoch;
    my $last_change = DateTime->from_epoch(epoch => $epoch);
    return sprintf('%04d-%02d-%02d', $last_change->year, $last_change->month,
        $last_change->day);
}

while(<>) {
    s/\Q{{LAST_CHANGE}}\E/last_change_for_file($input)/e;
    print $_;
}
