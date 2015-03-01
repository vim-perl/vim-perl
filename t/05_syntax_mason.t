#!/usr/bin/perl

use strict;
use warnings;
use File::Spec::Functions qw<catfile catdir>;
use Test::More tests => 6; # can we upgrade to 0.88 and use done_testing?
use Test::Differences;
use Text::VimColor 0.25;

my $lang = 'mason';
my $syntax_file = catfile('syntax', "$lang.vim");

sub parse_string {
    my ($string, $scripts) = @_;
    my $syntax = Text::VimColor->new(
        string => $string,
        extra_vim_options => [
            '+set runtimepath=.',       # don't consider system runtime files
            @{ $scripts || [] },
            "+source $syntax_file",
            '+syn sync fromstart',
        ],
    );
    return $syntax->marked;
}

eq_or_diff
    parse_string(<<MASON),
<%method title>Home</%method>
<h1><%perl>print "foobar";</%perl></h1>
MASON
    [
        [ Delimiter   => '<%method title>'  ],
        [ ''          => 'Home'   ],
        [ Delimiter   => '</%method>'    ],
        [ ''          => "\n<h1>"    ],
        [ Delimiter   => '<%perl>'  ],
        [ Statement   => "print" ],
        [ ''          => ' '  ],
        [ String      => '"foobar"' ],
        [ ''          => ';'  ],
        [ Delimiter   => "</%perl>" ],
        [ ''          => "</h1>\n"  ],
    ],
    'basic Template syntax';

eq_or_diff
    parse_string(<<MASON),
<%init>
=for foobar
some docs
=cut
print "foo";
</%init>
MASON
    [
        [ Delimiter   => '<%init>'  ],
        [ ''          => "\n"       ],
        [ Statement   => '=for'     ],
        [ Comment     => ' '        ],
        [ Identifier  => 'foobar'   ],
        [ ''          => "\n"       ],
        [ Comment     => 'some docs'],
        [ ''          => "\n"       ],
        [ Statement   => '=cut'     ],
        [ ''          => "\n"       ],
        [ Statement   => 'print'    ],
        [ ''          => ' '        ],
        [ String      => '"foo"'    ],
        [ ''          => ";\n"      ],
        [ Delimiter   => '</%init>' ],
        [ ''          => "\n"       ],
    ],
    'basic Template syntax';

eq_or_diff
    parse_string(<<'MASON'),
% if ($boolean) {
<li>hello</li>
% }
<& SELF:header &>
MASON
    [
        [ Delimiter       => '%'],
        [ ''              => ' '],
        [ Conditional     => 'if'],
        [ ''              => ' ('],
        [ Identifier      => '$boolean'],
        [ ''              => ") {\n<li>hello</li>\n"],
        [ Delimiter       => "%"],
        [ ''              => " }\n"],
        [ Delimiter       => "<& SELF:header"],
        [ ''              => ' '],
        [ Delimiter       => "&>"],
        [ ''              => "\n"],
    ],
    'basic Template syntax';

eq_or_diff
    parse_string(<<'MASON'),
<&| foo, bar => $baz &>
asdf
%# foo
<hlagh>
</&>
MASON
    [
        [ Delimiter        => '<&| foo'],
        [ ''               => ', '],
        [ String           => 'bar'],
        [ ''               => ' => '],
        [ Identifier       => '$baz'],
        [ ''               => ' '],
        [ Delimiter        => '&>'],
        [ ''               => "\nasdf\n"],
        [ Delimiter        => "%"],
        [ Comment          => '# foo'],
        [ ''               => "\n<hlagh>\n"],
        [ Delimiter        => "</&>"],
        [ ''               => "\n"],
    ],
    'basic Template syntax';

eq_or_diff
    parse_string(<<'MASON'),
% for my $t (qw{foo bar}) { # foo
<div>
% map { $_ => 'y' } qw(qa sa );
MASON
    [
        [Delimiter  =>'%'],
        [''         => ' '],
        [Repeat     => 'for'],
        [''         =>' '],
        [Statement  => 'my'],
        [''         => ' '],
        [Identifier => '$t'],
        [''         => ' ('],
        [String     => 'qw{foo bar}'],
        [''         => ') { '],
        [Comment    => '# foo'],
        [''         => "\n<div>\n"],
        [Delimiter  => '%'],
        [''         => ' '],
        [Statement  => 'map'],
        [''         => ' '],
        [Statement  => '{'],
        [''         => ' '],
        [Identifier => '$_'],
        [''         => ' => '],
        [String     => '\'y\''],
        [''         => ' '],
        [Statement  => '}'],
        [''         => ' '],
        [String     => 'qw(qa sa )'],
        [''         => ";\n"],
    ],
    'basic Template syntax';

eq_or_diff
    parse_string(<<'MASON'),
<% # This is a single-line comment
foo+2
%>
dsfsdf+2
<html>
<% # foo %>
<%
    # This is a
    # multi-line comment
%>
MASON
    [
        [Delimiter => '<%'],
        [''        => ' '],
        [Comment   => '# This is a single-line comment'],
        [''        => "\nfoo+"],
        [Number    => 2],
        [''        => "\n"],
        [Delimiter => '%>'],
        [''        => "\ndsfsdf+2\n<html>\n"],
        [Delimiter => '<%'],
        [''        => ' '],
        [Comment   => '# foo '],
        [Delimiter => '%>'],
        [''        => "\n"],
        [Delimiter => '<%'],
        [''        => "\n    "],
        [Comment   => '# This is a'],
        [''        => "\n    "],
        [Comment   => '# multi-line comment'],
        [''        => "\n"],
        [Delimiter => '%>'],
        [''        => "\n"],
    ],
    'basic Template syntax';

# TODO: done_testing;
