#!/usr/bin/env perl

use strict;
use warnings;
use lib 'tools';

use Local::MissingModule;
use Local::VimColor;
use Local::VimFolds;
use Local::Utils;
use Local::VisualDiff;

use File::Temp;
use JSON qw(decode_json);
use Parallel::ForkManager;
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
my $iter       = get_blob_iterator('origin/p5-corpus-ng', 'corpus');

$pm->run_on_finish(sub {
    my ( undef, $status, undef, undef, undef, $data ) = @_;

    my ( $filename, $expected_marked, $got_marked, $expected_folds, $got_folds ) = @$data;

    # XXX calculate differences in child?
    my $differences = find_differently_colored_lines($expected_marked, $got_marked);
    ok(!@$differences, "colors for file '$filename' match");
    if(@$differences) {
        diag_differences([ lines_from_marked($expected_marked) ],
            [ lines_from_marked($got_marked) ], $differences);
    }
    eq_or_diff($got_folds, $expected_folds, "folds for file '$filename' match");
});

while(my ( $filename, $content ) = $iter->()) {
    next unless $filename =~ /(?:pm|pl)\z/;
    next if $pm->start;

    my $marks_filename = ($filename =~ s{\Acorpus}{corpus_marked}r) . '.json';
    my $expected_marked = decode_json(get_corpus_contents($marks_filename));
    my @expected_folds  = get_folds_for($filename);

    my $source = File::Temp->new;
    print { $source } $content;
    close $source;

    my $got_marked  = $color->markup_file($source->filename);
    my @got_folds = $fold->_get_folds($source->filename);

    $pm->finish(0, [ $filename, $expected_marked, $got_marked, \@expected_folds, \@got_folds ]);
}

$pm->wait_all_children;

unless(Test::More->builder->is_passing) {
    diag <<'END_DIAG';
The corpus test failed!  This means that among the files stored under corpus/ in the p5-corpus-ng
branch, the syntax highlighting and/or the folding has changed for one or more files.  You need
to let a vim-perl maintainer know about this!

If you are a vim-perl maintainer, please see whether or not the changes in highlighting/folding
actually make sense.  If they do, simply run build-corpus.pl to rebuild the corpus and go on your
merry way.  If they do not, you've got some fixing to do ;)
END_DIAG
}

done_testing;
