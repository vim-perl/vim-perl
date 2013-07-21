#!/usr/bin/env perl

use strict;
use warnings;

use Cwd qw(getcwd);
use File::Copy qw(copy);
use File::Path qw(make_path);
use File::Spec;
use File::Temp;

my @FILES_TO_COPY = map {
    chomp; $_
} qx(git ls-files ftplugin indent syntax);

my $orig_wd     = getcwd();
my $temp_dir    = File::Temp->newdir;
my $archive_dir = File::Spec->catdir($temp_dir->dirname, 'vim-perl');

mkdir $archive_dir or die "Unable to create $archive_dir: $!";

foreach my $file (@FILES_TO_COPY) {
    my ( undef, $parent_dir ) = File::Spec->splitpath($file);

    make_path(File::Spec->rel2abs($parent_dir, $archive_dir));
    copy($file, File::Spec->rel2abs($file, $archive_dir)) or die "Unable to copy file '$file': $!";
}

my $pid = fork();
unless(defined $pid) {
    die "Unable to create child process: $!";
}

if($pid) {
    waitpid $pid, 0;
    unless($? == 0) {
        die 'Unable to create tarball (tar command failed)';
    }
} else {
    chdir $temp_dir->dirname or die "Unable to chdir to $temp_dir: $!";
    exec 'tar', 'czvf', File::Spec->catfile($orig_wd, 'vim-perl.tar.gz'), 'vim-perl';
    exit 255; # this will only run if exec fails
}
