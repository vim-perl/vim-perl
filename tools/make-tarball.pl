#!/usr/bin/env perl

use strict;
use warnings;

use Cwd qw(getcwd);
use DateTime;
use File::Path qw(make_path);
use File::Spec;
use File::Temp;

sub last_change_for_file {
    my ( $filename ) = @_;

    my $epoch = qx(git log -1 --format=format:%at -- $filename);
    chomp $epoch;
    my $last_change = DateTime->from_epoch(epoch => $epoch);
    return sprintf('%04d-%02d-%02d', $last_change->year, $last_change->month,
        $last_change->day);
}

sub run_template {
    my ( $input, $output ) = @_;

    my $in_fh;
    my $out_fh;

    open $in_fh, '<', $input or die "Unable to open '$input' for reading: $!";
    unless(open $out_fh, '>', $output) {
        close $in_fh;
        die "Unable to open '$output' for writing: $!";
    }

    while(<$in_fh>) {
        s/\Q{{LAST_CHANGE}}\E/last_change_for_file($input)/e;
        print { $out_fh } $_;
    }

    close $in_fh;
    close $out_fh;
}

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
    run_template($file, File::Spec->rel2abs($file, $archive_dir));
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
