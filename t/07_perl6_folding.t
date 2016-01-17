use strict;
use warnings;
use lib 'tools';

use Test::More tests => 1;
use Local::VimFolds;

my $folds = Local::VimFolds->new(
    language => 'perl6',
    options  => {
        perl6_fold => 1,
    },
);

$folds->folds_match(<<'END_PERL6', 'general folding');
class Foo { # {{{
    has $.dsfdsf;

    method bla { say "foo" }

    method Bar { # {{{
        say "dfdsf";
    } # }}}
} # }}}
grammar Foo { # {{{
    rule Foo { sdfsdf }

    rule Bla { # {{{
    } # }}}
} # }}}
sub foo { # {{{
} # }}}
our sub Foobar { # {{{
    dsfsdfsdfsdf
}; # }}}
my Int sub foo(Str $bar) { # {{{
    say $bar;
} # }}}
sub foo # {{{
{
} # }}}
END_PERL6
