# vim:ft=perl

use strict;
use warnings;

$log =~ s{
    (%d(?:{(.*?)})?)|   # $1: datetime $2: datetime fmt
    (?:%([%pmFLPn\$]))    # $3: others
}{
    if ($1 && $2) {
        my $dt_fmt = $2;
        my $now = ($dt_fmt =~ /\%[369]?N/)
            ? (Time::HiRes::time)
            : time;
        DateTime->from_epoch(epoch=>$now)->strftime($dt_fmt);
    }
    elsif ($1) {
        scalar localtime;
    }
    elsif ($3) {
        $p{$3};
    }
}egx;
