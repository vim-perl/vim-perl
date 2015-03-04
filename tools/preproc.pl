#!/usr/bin/env perl
use strict;
use warnings;

# This script is used to preprocess the perl6 syntax file to reduce
# repetition of common patterns. VimL requires cumbersome string
# concatenation and eval to reuse patterns, which makes for a lot of
# boilerplate code and a less readable regexes. So instead we preprocess
# the file to keep the original source more readable and easier to edit.
#
# A "macro" is defined by including lines in the source file which start
# with the VimL comment character (") followed by an identifier name
# surrounded by two sets of at-signs (@@FOO@@). This is followed by
# whitespace and then a double or single-quoted string containing the
# replacement text. Earlier macros can be interpolated into later macros.

my $preproc = '@@';
my %replacements;
while (my $line = <>) {
    my $check_line = $line;
    while ($check_line =~ /$preproc/) {
        $check_line = substr($check_line, $+[0]);
        if ($check_line !~ /^\w+$preproc/) {
            warn "Missing '$preproc' on line $.\n";
        }
        else {
            $check_line = substr($check_line, $+[0]);
        }
    }

    if ($line =~ /^"\s*$preproc(\w+)$preproc\s+(?:(.)(.+)\2)\s*$/) {
        my ($name, $content) = ($1, $3);
        $content =~ s/$preproc(\w+)$preproc/
            die "Replacement for $preproc$1$preproc not found at line $.\n" if !$replacements{$1};
            $replacements{$1}
        /eg;
        $replacements{$name} = $content;
    }
    else {
        $line =~ s/$preproc(\w+)$preproc/
            die "Replacement for $preproc$1$preproc not found at line $.\n" if !$replacements{$1};
            $replacements{$1}
        /eg;
    }
    print $line;
}
