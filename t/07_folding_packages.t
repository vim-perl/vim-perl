use strict;
use warnings;
use lib 'tools';

use Test::More tests => 10;
use Local::VimFolds;

my $pkg_folds = Local::VimFolds->new(
    language => 'perl',
    options  => {
        perl_fold => 1,
    },
);

my $nopkg_folds = Local::VimFolds->new(
    language => 'perl',
    options  => {
        perl_fold            => 1,
        perl_nofold_packages => 1,
    },
);

$pkg_folds->folds_match(<<'END_PERL', 'Non-brace packages that go until EOF fold correctly');
package Null; # {{{
my $null = bless {}, __PACKAGE__;
sub AUTOLOAD {$null}
sub ok       {0}
END_PERL
# no closing }}} means that the fold continues until the end of the buffer

$pkg_folds->folds_match(<<'END_PERL', '"1;" terminates the folding of a non-brace package');
package Null; # {{{
my $null = bless {}, __PACKAGE__;
sub AUTOLOAD {$null}
sub ok       {0}

1; # }}}
END_PERL

$pkg_folds->folds_match(<<'END_PERL', 'A new package starts a new fold');
package Null; # {{{
my $null = bless {}, __PACKAGE__;
sub AUTOLOAD {$null}
sub ok       {0} # }}}
package main; # {{{
sub ok {1}
1; # }}}
END_PERL
# no closing }}} means that the fold continues until the end of the buffer

$nopkg_folds->folds_match(<<'END_PERL', 'perl_nofold_packages disables folding');
package Null;
my $null = bless {}, __PACKAGE__;
sub AUTOLOAD {$null}
sub ok       {0}
END_PERL

$nopkg_folds->folds_match(<<'END_PERL', 'perl_nofold_packages disables folding');
package Null;
my $null = bless {}, __PACKAGE__;
sub AUTOLOAD {$null}
sub ok       {0}

1;
END_PERL

$nopkg_folds->folds_match(<<'END_PERL', 'perl_nofold_packages disables folding');
package Null;
my $null = bless {}, __PACKAGE__;
sub AUTOLOAD {$null}
sub ok       {0}
package main;
sub ok {1}
1;
END_PERL

    $pkg_folds->folds_match(<<'END_PERL', 'Brace packages fold correctly');
package Null { # {{{
my $null = bless {}, __PACKAGE__;
sub AUTOLOAD {$null}
sub ok       {0}
} # }}}
END_PERL

    $pkg_folds->folds_match(<<'END_PERL', q{"1;" doesn't terminate a brace package early});
package Null { # {{{
my $null = bless {}, __PACKAGE__;
sub AUTOLOAD {$null}
sub ok       {0}

1;

# }}}
END_PERL

$nopkg_folds->folds_match(<<'END_PERL', 'perl_nofold_packages disables folding');
package Null {
my $null = bless {}, __PACKAGE__;
sub AUTOLOAD {$null}
sub ok       {0}
}
END_PERL

    $nopkg_folds->folds_match(<<'END_PERL', 'perl_nofold_packages disables folding');
package Null {
my $null = bless {}, __PACKAGE__;
sub AUTOLOAD {$null}
sub ok       {0}

1;
END_PERL
