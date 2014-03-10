package Local::Utils;

use strict;
use warnings;
use parent 'Exporter';

use JSON qw(decode_json);

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

sub find_git_object {
    my ( $tree, $path ) = @_;

    my @paths = split('/', $path);

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

    return $tree;
}

sub get_blob_iterator {
    my ( $tree, $starting_path ) = @_;

    $tree = find_git_object($tree, $starting_path);

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

    open my $pipe, '-|', 'git', 'show', 'origin/p5-corpus:' . $filename;
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

our @EXPORT = qw(get_blob_iterator get_corpus_contents get_html_output_for get_folds_for find_git_object);

1;
