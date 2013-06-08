use strict;
use warnings;

BEGIN {
    require Tie::Hash;
    $INC{'Tie/StdHash.pm'} = 1;

    push @INC, sub {
        my ( undef, $module ) = @_;

        $module =~ s/[.]pm$//;
        $module =~ s{/}{::}g;

        die <<"END_DIE";
You seem to be missing the $module module; please install it to run this
script.  If you have cpanminus, you can simply do this:

  cpanm $module

END_DIE
    };
}

1;
