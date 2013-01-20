use strict;
use warnings;
use lib 't';

use Test::More tests => 1;
use VimFolds;

my $folds = VimFolds->new(
    syntax_file   => 'syntax/perl.vim',
    script_before => 'let perl_fold=1 | let perl_nofold_packages=1'
);

$folds->folds_match('t_source/perl/folding_subs.pm');
