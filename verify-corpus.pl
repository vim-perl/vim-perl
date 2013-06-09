#!/usr/bin/env perl

use strict;
use warnings;
use feature qw(say);
use lib 'tools';

use Local::MissingModule;
use Local::VimColor;
use Local::VimFolds;

use File::Find;
use File::Path qw(make_path);
use File::Slurp qw(read_file);
use File::Spec;
use JSON qw(decode_json);
use Parallel::ForkManager;
use Text::VimColor;
use Term::ProgressBar;

sub cmp_folds {
    my ( $got, $expected ) = @_;

    return unless @$got == @$expected;

    for(my $i = 0; $i < @$got; $i++) {
        return unless $got->[$i]{'level'} == $expected->[$i]{'level'};
        return unless $got->[$i]{'start'} == $expected->[$i]{'start'};
        return unless $got->[$i]{'end'}   == $expected->[$i]{'end'};
    }

    return 1;
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

my $revision = read_file('corpus_html/revision');
chomp $revision;
my $pretty_revision = qx(git log -1 --pretty=format:%d $revision);
chomp $pretty_revision;
$pretty_revision =~ s/^\s+|\s+$//g;
if($pretty_revision) {
    $pretty_revision =~ s/^\(|\)$//g;
} else {
    $pretty_revision = $revision;
}
say STDERR "verifying against corpus built with $pretty_revision...";

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

my $pm   = Parallel::ForkManager->new(16);
my $code = 0;
$pm->run_on_finish(sub {
    my ( undef, $exit ) = @_;

    $code = 1 unless $exit == 0;
});

for(my $i = 0; $i < @corpus_files; $i++) {
    my $pid = $pm->start;
    if($pid) {
        next;
    }

    my $source      = $corpus_files[$i];
    my $output      = $output_files[$i];
    my $fold_output = $output_files[$i];

    $fold_output =~ s/[.]html$/-folds.json/;

    my $got      = read_file($output);
    my $expected = $color->color_file($source);

    my $code = 0;
    unless($got eq $expected) {
        my @got_lines      = split /\n/, $got;
        my @expected_lines = split /\n/, $expected;
        say "colors: $source";
        $code = 1;
    }

    my @got_folds      = $fold->_get_folds($source);
    my $expected_folds = decode_json(read_file($fold_output));

    unless(cmp_folds(\@got_folds, $expected_folds)) {
        say "folds: $source";
        $code = 1;
    }

    $pm->finish($code);
}

$pm->wait_all_children;

exit($code);
