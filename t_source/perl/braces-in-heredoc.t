#!/usr/bin/env perl

use strict;
use warnings;

sub foo {
    my $x = <<'PERL';
sub func1 {
    print 'In a heredoc';
} # Syntax highlighting things this brace closes foo()'s body

# This function is highlighted as if it is not in a heredoc.
sub func2 {
    print 'Still in a heredoc';
}
PERL

    print 'Out of the heredoc';
}
