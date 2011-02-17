use strict;
use warnings;
use Test::More;
use Text::VimColor;

# copied from t/01_highlighting.t; something could be put into t/lib
use File::Spec::Functions qw(catfile);
my $color_file = catfile('t', 'define_all.vim');
my $lang = 'cpanchanges';
    my $syntax_file   = catfile('syntax',   "$lang.vim");
    my $ftplugin_file = catfile('ftplugin', "$lang.vim");
    my $hilite = Text::VimColor->new(
        vim_options            => [
            qw(-RXZ -i NONE -u NONE -U NONE -N -n), # for performance
            '+set nomodeline',          # for performance
            '+set runtimepath=.',       # don't consider system runtime files
            "+source $ftplugin_file",
            "+source $syntax_file",
            "+source $color_file",      # all syntax classes should be defined
        ],
    );

# cpanchanges

my %groups;
{
    # fill %groups with things like 'Version' => 'Identifier'
    open(my $fh, '<', $syntax_file) or die("Failed to open '$syntax_file': $!");
    while( my $line = <$fh> ){
        $line =~ /^HiLink cpanchanges(\w+)\s+(\w+)/
            and $groups{$1} = $2;
    }
    close($fh);
}

my @tests = (

# everything
[ <<'CHANGES'
Revision history for Local::Module

{{$NEXT}}

1.001 2011-02-17

  - Changed everything
  - Ingored bug:
    RT: #000000

1.000001 2011-02-16

  * Initial release to CPAN
CHANGES
, [
    [$groups{Preamble},     'Revision history for Local::Module'], ['',"\n\n"],
    [$groups{NextRelease},  '{{$NEXT}}'], ['',"\n\n"],
    [$groups{Version},      '1.001'], ['',' '],
    [$groups{Date},         '2011-02-17'], ['',"\n\n  "],
    [$groups{ItemMarker},   '-'],
    ['',                    " Changed everything\n  "],
    [$groups{ItemMarker},   '-'],
    ['',                    " Ingored bug:\n    RT: #000000\n\n"],
    [$groups{Version},      '1.000001'], ['',' '],
    [$groups{Date},         '2011-02-16'], ['', "\n\n  "],
    [$groups{ItemMarker},   '*'],
    ['',                    " Initial release to CPAN\n"]
]],

# preamble, single release, no next token
[ <<'CHANGES'
Revision history for Local::Module

1.00  2011-02-16

 - Initial release to CPAN
CHANGES
, [
    [$groups{Preamble},     'Revision history for Local::Module'], ['',"\n\n"],
    [$groups{Version},      '1.00'], ['','  '],
    [$groups{Date},         '2011-02-16'], ['', "\n\n "],
    [$groups{ItemMarker},   '-'],
    ['',                    " Initial release to CPAN\n"]
]],

# preamble, next token, no actual releases
[ <<'CHANGES'
Changelog (duh)

{{$NEXT}}
CHANGES
, [
    [$groups{Preamble},     'Changelog (duh)'], ['',"\n\n"],
    [$groups{NextRelease},  '{{$NEXT}}'], ['',"\n"],
]],

# no preamble, next token, no actual releases
[ <<'CHANGES'
{{$NEXT}}
CHANGES
, [
    [$groups{NextRelease},  '{{$NEXT}}'], ['',"\n"],
]],

# no preamble, single release, tab
[ <<"CHANGES"
v1.2.3\t2011-02-16

  * Initial release to CPAN
CHANGES
, [
    [$groups{Version},      'v1.2.3'], ['',"\t"],
    [$groups{Date},         '2011-02-16'], ['', "\n\n  "],
    [$groups{ItemMarker},   '*'],
    ['',                    " Initial release to CPAN\n"]
]],

# no preamble, single release, no item marker, no spacer line
[ <<"CHANGES"
v1\t2011-02-16
  Initial release to CPAN
CHANGES
, [
    [$groups{Version},      'v1'], ['',"\t"],
    [$groups{Date},         '2011-02-16'],
    ['',                    "\n  Initial release to CPAN\n"]
]],

# example of alternate (but valid) format
[ <<'CHANGES'
3.123456  2011-02-16 20:19:18 America/New_York

          Add Something

          Change something else
          that I won't describe
CHANGES
, [
    [$groups{Version},      '3.123456'], ['',"  "],
    [$groups{Date},         '2011-02-16'],
    ['', " 20:19:18 America/New_York\n\n          Add Something\n\n          Change something else\n          that I won't describe\n"],
]],

);

plan tests => scalar @tests;

foreach my $test ( @tests ){
    my ($string, $marked) = @$test;
    $hilite->syntax_mark_string($string, filetype => $lang);
    is_deeply($hilite->marked, $marked, 'output marked expectedly');
}
