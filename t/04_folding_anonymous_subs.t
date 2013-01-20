use strict;
use warnings;
use lib 't';

use Test::More tests => 2;
use VimFolds;

my $no_anon_folds = VimFolds->new(
    language      => 'perl',
    script_before => 'let perl_fold=1 | let perl_nofold_packages=1'
);

my $anon_folds = VimFolds->new(
    language      => 'perl',
    script_before => 'let perl_fold=1 | let perl_nofold_packages=1 | let perl_fold_anonymous_subs=1'
);

$no_anon_folds->folds_match(<<'END_PERL');
use strict;
use warnings;

my $anon_sub = sub {
    print "one\n";
    print "two\n";
    print "three\n";
};
END_PERL

$anon_folds->folds_match(<<'END_PERL');
use strict;
use warnings;

my $anon_sub = sub { # {{{
    print "one\n";
    print "two\n";
    print "three\n";
}; # }}}
END_PERL
