use strict;
use warnings;
use lib 't';

use Test::More tests => 1;
use VimFolds;

my $folds = VimFolds->new(
    syntax_file   => 'syntax/perl6.vim',
    script_before => 'let perl6_fold = 1',
);

$folds->folds_match('t_source/perl6/subroutines.p6');
