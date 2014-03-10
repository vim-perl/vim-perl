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

my $pm   = Parallel::ForkManager->new(16);
my $iter = get_blob_iterator('p5-corpus', 'corpus');

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

    # XXX children!
    eq_or_diff($got_html, $expected_html, "colors for file '$filename' differ");
    eq_or_diff(\@got_folds, \@expected_folds, "folds for file '$filename' differ");

    $pm->finish;
}

$pm->wait_all_children;

done_testing;
