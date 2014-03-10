#!/usr/bin/env perl

use strict;
use warnings;
use lib 'tools';

use Local::MissingModule;
use Local::VimColor;
use Local::VimFolds;
use Local::Utils;

use File::Temp;
use Parallel::ForkManager;
use Path::Tiny;
use Test::Differences;
use Test::More;
use Test::SharedFork;

my $color = Local::VimColor->new(
    language => 'perl',
);

my $fold = Local::VimFolds->new(
    options => {
        perl_fold                => 1,
        perl_nofold_packages     => 1,
        perl_fold_anonymous_subs => 1,
    },
    language => 'perl',
);

my $pm         = Parallel::ForkManager->new(16);
my $iter       = get_blob_iterator('origin/p5-corpus', 'corpus');
my $is_passing = 1;

$pm->run_on_finish(sub {
    my ( undef, $status ) = @_;

    $is_passing &&= ($status == 0);
});

while(my ( $filename, $content ) = $iter->()) {
    next unless $filename =~ /(?:pm|pl)\z/;
    next if $pm->start;

    my $expected_html  = get_html_output_for($filename);
    my @expected_folds = get_folds_for($filename);

    my $source = File::Temp->new;
    print { $source } $content;
    close $source;

    my $got_html  = $color->color_file($source->filename);
    my @got_folds = $fold->_get_folds($source->filename);

    eq_or_diff($got_html, $expected_html, "colors for file '$filename' match");
    eq_or_diff(\@got_folds, \@expected_folds, "folds for file '$filename' match");

    $pm->finish(Test::More->builder->is_passing ? 0 : 1);
}

$pm->wait_all_children;

unless($is_passing) {
    diag <<'END_DIAG';
The corpus test failed!  This means that among the files stored under corpus/ in the p5-corpus
branch, the syntax highlighting and/or the folding has changed for one or more files.  You need
to let a vim-perl maintainer know about this!

If you are a vim-perl maintainer, please see whether or not the changes in highlighting/folding
actually make sense.  If they do, simply run build-corpus.pl to rebuild the corpus and go on your
merry way.  If they do not, you've got some fixing to do ;)
END_DIAG
}

done_testing;
