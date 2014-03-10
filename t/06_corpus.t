#!/usr/bin/env perl

use strict;
use warnings;
use lib 'tools';

use Local::MissingModule;
use Local::VimColor;
use Local::VimFolds;

use File::Temp;
use JSON qw(decode_json);
use Parallel::ForkManager;
use Path::Tiny;
use Test::Differences;
use Test::More;
use Test::SharedFork;

my $GIT_LS_TREE = qr{
    \A
    (?<permissions>\d+)
    \s+
    (?<object_type>blob|tree)
    \s+
    (?<object_id>[a-fA-F0-9]{40})
    \s+
    (?<filename>\S+)
    \z
}x;

sub get_blob_iterator {
    my ( $tree, $starting_path ) = @_;

    my @paths = split('/', $starting_path);

    while(@paths) {
        my $directory = shift @paths;

        my $found_tree;

        open my $pipe, '-|', 'git', 'ls-tree', $tree;
        while(<$pipe>) {
            chomp;

            if(/$GIT_LS_TREE/) {
                if($directory eq $+{'filename'}) {
                    $found_tree = 1;
                    $tree       = $+{'object_id'};
                    last;
                }
            } else {
                die "Invalid output from git-ls-tree: $_";
            }
        }
        close $pipe;

        unless($found_tree) {
            die "Unable to find path component '$directory'";
        }
    }

    open my $pipe, '-|', 'git', 'ls-tree', '-r', $tree;

    return sub {
        my $line = <$pipe>;

        unless(defined($line)) {
            close $pipe;
            return;
        }

        chomp $line;

        if($line =~ /$GIT_LS_TREE/) {
            my ( $object_id, $filename ) = @+{qw/object_id filename/};

            open my $other_pipe, '-|', 'git', 'cat-file', 'blob', $object_id;
            my $content = do {
                local $/;
                <$other_pipe>;
            };
            close $other_pipe;

            return ( $starting_path . '/' . $filename, $content );
        } else {
            die "Invalid output from git-ls-tree: $line";
        }
    };
}

sub get_corpus_contents {
    my ( $filename ) = @_;

    open my $pipe, '-|', 'git', 'show', 'p5-corpus:' . $filename;
    my $content = do {
        local $/;
        <$pipe>
    };
    close $pipe;
    return $content;
}

sub get_html_output_for {
    my ( $filename ) = @_;

    $filename  =~ s{\Acorpus/}{corpus_html/};
    $filename .= '.html';

    return get_corpus_contents($filename);
}

sub get_folds_for {
    my ( $filename ) = @_;

    $filename  =~ s{\Acorpus/}{corpus_html/};
    $filename .= '-folds.json';

    my $contents = get_corpus_contents($filename);

    return @{ decode_json($contents) };
}

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
