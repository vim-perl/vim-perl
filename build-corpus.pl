#!/usr/bin/env perl

use strict;
use warnings;
use autodie;
use lib 'tools';

use Local::MissingModule;
use Local::VimColor;
use Local::VimFolds;
use Local::Utils;

use File::Temp;
use JSON qw(encode_json);

sub insert_into_tree {
    my ( $tree, $path, $content ) = @_;

    my @path_components = split(qr{/}, $path);
    my $filename        = pop @path_components;

    foreach my $component (@path_components) {
        unless(exists $tree->{$component}) {
            $tree->{$component} = {};
        }

        if(ref($tree->{$component}) ne 'HASH') { # if it's a leaf
            die 'freak out';
        }

        $tree = $tree->{$component};
    }
    $tree->{$filename} = $content;
}

sub two_way_pipe {
    my $input = pop;
    my @cmd   = @_;

    my ( $child_read, $child_write, $parent_read, $parent_write );

    pipe($child_read, $parent_write);
    pipe($parent_read, $child_write);

    my $pid = fork;

    if($pid) {
        close $child_read;
        close $child_write;

        print { $parent_write } $input;
        close $parent_write;
        my $output = do {
            local $/;
            <$parent_read>;
        };
        close $parent_read;

        waitpid $pid, 0;

        if($? != 0) {
            local $" = ' ';
            die "Running @cmd exited with a non-zero status";
        }

        return $output;
    } else {
        close $parent_read;
        close $parent_write;

        open STDIN, '<&', $child_read;
        open STDOUT, '>&', $child_write;

        exec @cmd;
        exit 255;
    }
}

sub create_blob {
    my ( $contents ) = @_;
    my $blob_id = two_way_pipe('git', 'hash-object', '-w', '--stdin', $contents);
    chomp $blob_id;
    return $blob_id;
}

sub create_tree {
    my ( $tree ) = @_;

    my @files;

    foreach my $filename (sort keys %$tree) {
        my $contents = $tree->{$filename};

        if(ref($contents) eq 'HASH') {
            my $tree_id = create_tree($contents);
            push @files, "040000 tree $tree_id\t$filename";
        } else {
            my $blob_id = create_blob($contents);
            push @files, "100644 blob $blob_id\t$filename";
        }
    }

    my $content = join("\n", @files);

    my $object_id = two_way_pipe('git', 'mktree', $content);
    chomp $object_id;

    return $object_id;
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

my $json = JSON->new->utf8->canonical;

my $iter = get_blob_iterator('p5-corpus', 'corpus');
my $tree = {};

while(my ( $filename, $contents ) = $iter->()) {
    next unless $filename =~ /(?:pm|pl)\z/;

    my $source = File::Temp->new;
    print { $source } $contents;
    close $source;

    my $html  = $color->color_file($source->filename);
    my @folds = $fold->_get_folds($source->filename);

    my $html_filename = $filename;
    $html_filename    =~ s{\Acorpus/}{};
    $html_filename   .= '.html';

    my $folds_filename = $filename;
    $folds_filename    =~ s{\Acorpus/}{};
    $folds_filename   .= '-folds.json';

    insert_into_tree($tree, $html_filename, $html);
    insert_into_tree($tree, $folds_filename, $json->encode(\@folds));
}

$tree = create_tree($tree);

my $corpus_tree = find_git_object('p5-corpus', 'corpus');

$tree = two_way_pipe('git', 'mktree', "040000 tree $tree\tcorpus_html\n040000 tree $corpus_tree\tcorpus\n");
chomp $tree;

open my $pipe, '-|', 'git', 'commit-tree', '-m', 'Update Perl 5 corpus', $tree;
my $commit = <$pipe>;
close $pipe;
chomp $commit;

system 'git', 'update-ref', 'refs/heads/p5-corpus', $commit;
system 'git', 'push', 'origin', '--force', 'p5-corpus:p5-corpus';
