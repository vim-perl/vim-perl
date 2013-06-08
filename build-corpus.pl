#!/usr/bin/env perl

use strict;
use warnings;
use lib 'tools';

use Local::MissingModule;
use Local::VimColor;
use Local::VimFolds;

use File::Find;
use File::Path qw(make_path);
use File::Spec;
use File::Slurp qw(write_file);
use JSON qw(encode_json);
use Parallel::ForkManager;
use Term::ProgressBar;

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

my @corpus_files;
my @output_files;

find({ wanted => sub {
    return unless /[.](?:pm|pl)$/;

    my $path = $File::Find::name;

    push @corpus_files, $path;

    my ( undef, $dir, $file ) = File::Spec->splitpath($path);
    my @dirs = File::Spec->splitdir($dir);
    $dirs[0] = 'corpus_html';
    push @output_files, File::Spec->catfile(@dirs, $file . '.html');
    make_path(File::Spec->catdir(@dirs), {
        verbose => 1,
    });
}, no_chdir => 1}, 'corpus');

# XXX don't allow building when dirty?
write_file('corpus_html/revision', `git rev-parse HEAD`);

my $p  = Term::ProgressBar->new({ count => scalar(@corpus_files) });
my $pm = Parallel::ForkManager->new(16);

for(my $i = 0; $i < @corpus_files; $i++) {
    my $pid = $pm->start;
    if($pid) {
        $p->update($i);
        next;
    }

    my $source      = $corpus_files[$i];
    my $output      = $output_files[$i];
    my $fold_output = $output_files[$i];

    $fold_output =~ s/[.]html$/-folds.json/;

    write_file($output, $color->color_file($source));

    my @folds = $fold->_get_folds($source);

    write_file($fold_output, encode_json(\@folds));

    $pm->finish;
}
