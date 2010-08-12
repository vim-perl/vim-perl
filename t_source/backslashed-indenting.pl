use warnings;
use strict;

my $foo;
my $bar;

# There was a bug where indent/perl.vim saw a backslash as a closing
# bracket, thus goofing up indents.
if ( $foo ) {
    if ( $bar +
        $y +
        $x
        == 14
    ) {
        $x = [
            qw(
            foo
            \
            bar
            ]
            bat
            ),
            "\x"
        ];
        $x = '\x';
    }
}
