#!/usr/bin/perl

# This is shamelessly ripped from $VIMRUNTIME/tools/efm_perl.pl (which was last
# updated in 2001 according to the version history--but I'm willing to accept
# that someone has probably made changes to it since then.) Check that file for
# details and historical information.

use strict;
use warnings;

use Cwd;
use File::Basename;

die "Too many arguments!\n" if @ARGV > 1;

my $file = shift or die "No filename to check!\n";
my $dir  = dirname( $file ) . '/lib';
my $cwd  = cwd() . '/lib';

my $error = qr{(.*)\sat\s(.*)\sline\s(\d+)(\.|,\snear\s\".*\"?)};

# Error messages to be skipped.
my @skip = (

  '"DB::single" used only once: possible typo',
  'BEGIN failed--compilation aborted',

);

my $skip = join '|', @skip;

# Thanks to
#
# http://blogs.perl.org/users/ovid/2011/01/warningsunused-versus-ppi.html for
# the 'warnings::unused' trick.
#
# https://github.com/Ovid/DB--Color.git for the 'circular::require' trick

# Note: Most of the following modules need to be installed, most are not
# included in core.

my @checks;

push @checks, '-M-circular::require' if `perldoc -l circular::require 2> /dev/null`;
push @checks, '-M-indirect'          if `perldoc -l indirect 2> /dev/null`;
push @checks, '-Mwarnings::method'   if `perldoc -l warnings::method 2> /dev/null`;
push @checks, '-Mwarnings::unused'   if `perldoc -l warnings::unused 2> /dev/null`;

# uninit is not included in 5.10 and later
push @checks, '-Muninit'             if ( $] < 5.010 ) && `perldoc -l uninit 2> /dev/null`;

# need to turn on taint if it's on the shebang line.
# naive check for [tT] switch ... will both t and T ever be used at the same time?
my ( $taint ) = `head -n 1 $file` =~ /\s.*-.*?(t)/i;
push @checks, "-$taint" if defined $taint;

my ( $message, $extracted_file, $lineno, $rest );

for my $line ( `perl -I $dir -I $cwd @checks -c $file 2>&1` ) {

  chomp $line;
  next if $line =~ /$skip/;
  $line =~ s/([()])/\\$1/g;

  if ( ( $message, $extracted_file, $lineno, $rest ) = $line =~ /^$error$/ ) {

    $message .= $rest if ($rest =~ s/^,//);
    print "$file:$lineno:$message\n";

  }
}
