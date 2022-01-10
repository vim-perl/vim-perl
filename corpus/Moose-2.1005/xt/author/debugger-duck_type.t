#!/usr/bin/perl

use FindBin qw/ $Bin /;

BEGIN {
#line 1
#!/usr/bin/perl -d

    push @DB::typeahead, "c", "q";

    # try to shut it up at least a little bit
    open my $out, ">", \my $out_buf;
    $DB::OUT = $out;
    open my $in, "<", \my $in_buf;
    $DB::IN = $in;
}

require "$Bin/../../t/type_constraints/duck_types.t";
