#!/usr/bin/perl

use strict;
use warnings;
use File::Spec::Functions qw<catfile catdir>;
use Test::More tests => 3; # can we upgrade to 0.88 and use done_testing?
use Test::Differences;
use Text::VimColor;

# hack to work around a silly limitation in Text::VimColor,
# will remove it when Text::VimColor has been patched
{
    package TrueHash;
    use base 'Tie::StdHash';
    sub EXISTS { return 1 };
}
tie %Text::VimColor::SYNTAX_TYPE, 'TrueHash';

my $lang = 'tt2';
my $syntax_file   = catfile('syntax', "$lang.vim");
my $color_file    = catfile('t', 'define_all.vim');

sub parse_string {
    my ($string, $scripts) = @_;
    my $syntax = Text::VimColor->new(
        string => $string,
        vim_options => [
            qw(-RXZ -i NONE -u NONE -U NONE -N -n), # for performance
            '+set nomodeline',          # for performance
            '+set runtimepath=.',       # don't consider system runtime files
            @{ $scripts || [] },
            "+source $syntax_file",
            "+source $color_file",      # all syntax classes should be defined
        ],
    );
    return $syntax->marked;
}

eq_or_diff
    parse_string(<<TT2),
[% IF 1 %]
    true
[% ELSE %]
    false
[% END %]
TT2
    [
        [ Type      => '[% '  ],
        [ Statement => 'IF'   ],
        [ Type      => ' '    ],
        [ Number    => '1'    ],
        [ Type      => ' %]'  ],
        [ ''        => "\n    true\n" ],
        [ Type      => '[% '  ],
        [ Statement => 'ELSE' ],
        [ Type      => ' %]'  ],
        [ ''        => "\n    false\n" ],
        [ Type      => '[% '  ],
        [ Statement => 'END' ],
        [ Type      => ' %]'  ],
        [ ''        => "\n" ],
    ],
    'basic Template syntax';

eq_or_diff
    parse_string(<<TT2),
[% PERL %]
    print("vim");
[% END %]
TT2
    [
        [ Type      => '[% '  ],
        [ Statement => 'PERL' ],
        [ Type      => ' %]'  ],
        [ ''        => "\n" ],
        [ 'tt2_perlcode' => '    ' ],
        [ Identifier => 'print(' ],
        [ String    => '"vim"' ],
        [ 'tt2_perlcode' => ');' ],
        [ ''        => "\n" ],
        [ Type      => '[% '  ],
        [ Statement => 'END' ],
        [ Type      => ' %]'  ],
        [ ''        => "\n" ],
    ],
    'perl syntax included';

eq_or_diff
    parse_string(<<TT2, ['+let b:tt2_syn_inc_perl = 0']),
[% PERL %]
    print("vim");
[% END %]
TT2
    [
        [ Type      => '[% '  ],
        [ Statement => 'PERL' ],
        [ Type      => ' %]'  ],
        [ ''        => "\n    print(\"vim\");\n" ],
        [ Type      => '[% '  ],
        [ Statement => 'END' ],
        [ Type      => ' %]'  ],
        [ ''        => "\n" ],
    ],
    'perl syntax disabled';

# TODO: done_testing;
