package Regexp::Debugger;

use warnings;
use strict;
eval "use feature 'evalbytes'";         # Experimental fix for Perl 5.16

our $VERSION = '0.001016';

# Handle Perl 5.18's new-found caution...
no if $] >= 5.018, warnings => "experimental::smartmatch";

# Give an accurate warning if used with an antique Perl...
BEGIN {
    if ($] < 5.010001) {
        die sprintf "Regexp::Debugger requires Perl v5.10.1 or later (at %s line %s)\n",
                     (caller 2)[1..2];
    }
}

use 5.010001; # ...activate all the tasty 5.10 goodies

use List::Util qw< min max first sum >;

# Track configurable options lexically...
my @config;

# Track debugging history in various formats...
my %history_of;

# Persistent information within debugger...
my $prev_regex_pos;   # ...track where we were previously in the regex
my $prev_str_pos;     # ...track where we were previously in the string
my %capture;          # ...track capture groups within regex
my $pre_is_pending;   # ...did we try something last event?
my $interaction_quit; # ...did we get a quit request?
my $interaction_mode; # ...step-by-step, jump to match, or continue?
my $display_mode;     # ...how is the match being visualized at present?


# Colours for heatmaps...
my @DEF_HEAT_COLOUR = (
    'white  on_black',    #  0-20  percentile
    'cyan   on_blue',     # 20-40  percentile
    'blue   on_cyan',     # 40-60  percentile
    'red    on_yellow',   # 60-80  percentile
    'yellow on_red',      # 80-100 percentile
);

# Colours for detailed regex descriptions...
my %DESCRIPTION_COLOUR = (
    desc_sep_col   => 'blue on_black underline',
    desc_regex_col => 'white on_black',
    desc_text_col  => 'cyan on_black',
);

# Colour for error messages...
my $ERR_COL = 'red';


# Default config which any explicit config modifies...
my @SHOW_WS_OPTIONS = qw< compact  visible  original >;
my %DEFAULT_CONFIG = (
    # How debugging info is displayed initially...
    display_mode  => 'visual',

    # Colour scheme for debugging info...
    info_col  => '       white on_black',
    try_col   => 'bold magenta on_black',
    match_col => '   bold cyan on_black',
    fail_col  => '      yellow on_red',
    ws_col    => '   bold blue underline',

    # Colour scheme for regex descriptions...
    %DESCRIPTION_COLOUR,

    # Where debugging info is written to (undef --> STDOUT)...
    save_to_fh    => undef,

    # How whitespace is managed...
    show_ws       => $SHOW_WS_OPTIONS[0],
);

# The current config...
my $lexical_config = \%DEFAULT_CONFIG;
# Simulate print() and say() on appropriate filehandle...
sub _print {
    if (!$lexical_config->{save_to_fh}) {
        no warnings 'utf8';
        print @_;
    }
}

sub _say {
    if (!$lexical_config->{save_to_fh}) {
        no warnings 'utf8';
        say @_;
    }
}

# How should matches be indicated???
my $MATCH_DRAG = ' ';

# Will heatmaps be visible???
my $heatmaps_invisible;

# Indent unit for hierarchical display...
my $INDENT = q{  };

# Simulate Term::ANSIColor badly (if necessary)...
CHECK {
    my $can_color
        = ( $^O ne 'MSWin32' or eval { require Win32::Console::ANSI } )
          && eval { require Term::ANSIColor };

    if ( !$can_color ) {
        *Term::ANSIColor::colored = sub { return shift };
        $MATCH_DRAG         = '_';
        $heatmaps_invisible = 1;
    }
}

# Load the module...
sub import {
    use Carp;

    # Don't need the module name...
    shift;

    # Export re 'eval' semantics...
    $^H |= 0x00200000;

    # Unpack the arguments...
    if (@_ % 2) {
        croak 'Odd number of configuration args after "use Regexp::Debugger"';
    }
    my %arg = @_;

    # Creat a new lexically scoped config and remember its index...
    push @config, { %DEFAULT_CONFIG };
    $^H{'Regexp::Debugger::lexical_scope'} = $#config;

    _load_config(\%arg);

    # Signal lexical scoping (active, unless something was exported)...
    $^H{'Regexp::Debugger::active'} = 1;

    # Process any regexes in module's active lexical scope...
    use overload;
    overload::constant(
        qr => sub {
            my ($raw, $cooked, $type) = @_;

            my $lexical_scope = (caller 1)[10]{'Regexp::Debugger::lexical_scope'};

            # In active scope and really a regex and interactivity possible...
            my $is_interactive = defined $arg{save_to} || -t *STDIN && -t *STDOUT;
            if (_module_is_active() && $type =~ /qq?/ && $is_interactive) {
                return bless {cooked=>$cooked, lexical_scope=>$lexical_scope}, 'Regexp::Debugger::Precursor';
            }
            # Ignore everything else...
            else {
                return $cooked;
            }
        }
    );
}

# Deactivate module's regex effect when it is "anti-imported" with 'no'...
sub unimport {
    # Signal lexical (non-)scoping...
    $^H{'Regexp::Debugger::active'} = 0;
}

# Encapsulate the hoopy user-defined pragma interface...
sub _module_is_active {
    return (caller 1)[10]->{'Regexp::Debugger::active'};
}

# Load ~/.rxrx config...
sub _load_config {
    my $explicit_config_ref = shift();
    my %config;

    # Work out where to look...
    my $home_dir = $ENV{HOME};
    if (!$home_dir && eval { require File::HomeDir } ) {
        $home_dir = File::HomeDir->my_home;
    }

    # Find config file...
    CONFIG_FILE:
    for my $config_file ( '.rxrx', ( $home_dir ? "$home_dir/.rxrx" : () ) ) {

        # Is this a readable config file???
        open my $fh, '<', $config_file
            or next CONFIG_FILE;

        # Read and parse config file...
        CONFIG_LINE:
        for my $config_line (<$fh>) {
            if ($config_line =~ /^\s*(.*?)\s*[:=]\s*(.*?)\s*$/) {
                $config{$1} = $2;
            }
        }

        last CONFIG_FILE;
    }

    # Make any explicit args override .rxrxrc config...
    %config = (display => 'visual', %config, %{$explicit_config_ref});

    # Configure colour scheme for displays...
    for my $colour (grep /_col$/, keys %DEFAULT_CONFIG) {
        if (exists $config{$colour}) {
            $config[-1]{$colour} = $config{$colour}
        }
    }

    # Configure how whitespace is displayed...
    my $show_ws = $config{show_ws};
    if (defined $show_ws) {
        if ($show_ws ~~ @SHOW_WS_OPTIONS) {
            $config[-1]{show_ws} = $show_ws;
        }
        else {
            croak "Unknown 'show_ws' option: '$show_ws'";
        }
    }

    # Configure heatmap colour scheme...
    my @heatmap_cols =
        map { $config{$_} }
        sort {
            # Sort numerically (if feasible), else alphabetically...
            my $a_key = $a =~ /(\d+)/ ? $1 : undef;
            my $b_key = $b =~ /(\d+)/ ? $1 : undef;
            defined $a_key && defined $b_key
                ? $a_key <=> $b_key
                : $a     cmp $b;
        }
        grep { /^heatmap/ }
        keys %config;

    if (!@heatmap_cols) {
        @heatmap_cols = @DEF_HEAT_COLOUR;
    }

    $config[-1]{heatmap_col} = \@heatmap_cols;


    # Configure initial display mode...
    my $display = $config{display};
    if (defined $display) {
        $config[-1]{display_mode}
            = $display =~ m{^events}i  ? 'events'
            : $display =~ m{^heatmap}i ? 'heatmap'
            : $display =~ m{^visual}i  ? 'visual'
            : $display =~ m{^JSON}i    ? 'JSON'
            : croak "Unknown 'display' option: '$display'";
    }

    # Configure destination of debugging info...
    my $save_to = $config{save_to};
    if (defined $save_to) {
        use Scalar::Util qw< openhandle >;
        if (openhandle($save_to)) {
            $config[-1]{save_to_fh} = $save_to;
        }
        elsif (!ref $save_to) {
            my ($mode, $filename) = $save_to =~ m{ (>{0,2}) (.*) }x;
            open my $fh, $mode||'>', $filename
                or croak "Invalid 'save_to' option: '$save_to'\n($!)";
            $config[-1]{save_to_fh} = $fh;
        }
        else {
            croak "Invalid 'save_to' option: ", ref($save_to);
        }
    }
}


# General memory for each state of each regex...
# (structure is: $state{REGEX_NUM}{STATE_NUMBER}{ATTRIBUTE})
my %state;
my $next_regex_ID = 0;


#=====[ COMPILE-TIME INTERIM REPRESENTATION OF REGEXES ]===================
{
    package Regexp::Debugger::Precursor;

    # Only translate precursors once...
    state %regex_cache;

    use overload (
        # Concatenation/interpolation just concatenates to the precursor...
        q{.} => sub {
            my ($x, $y, $reversed) = @_;

            # Where are we from???
            my $lexical_scope = $x->{lexical_scope} // 0;

            # Reorder if necessary...
            if ($reversed) { ($y,$x) = ($x,$y); }

            # Unpack if objects...
            if (ref $x) { $x = eval{ $x->{cooked} } // $x }
            if (ref $y) { $y = eval{ $y->{cooked} } // $y }

            # Undo overeager \Q if necessary...
               if ($x =~ m{^\\\(\\\?\\\#R_d\\:(\d+)\\\)}) { $x = '\\Q' . $state{$1}{raw_regex}     . '\\E' }
            elsif ($x =~ m{^\(\?\#R_D:(\d+)\)})           { $x = '\\U' . uc($state{$1}{raw_regex}) . '\\E' }
            elsif ($x =~ m{^\(\?\#r_d:(\d+)\)})           { $x = '\\L' . lc($state{$1}{raw_regex}) . '\\E' }
               if ($y =~ m{^\\\(\\\?\\\#R_d\\:(\d+)\\\)}) { $y = '\\Q' . $state{$1}{raw_regex}     . '\\E' }
            elsif ($y =~ m{^\(\?\#R_D:(\d+)\)})           { $y = '\\U' . uc($state{$1}{raw_regex}) . '\\E' }
            elsif ($y =~ m{^\(\?\#r_d:(\d+)\)})           { $y = '\\L' . lc($state{$1}{raw_regex}) . '\\E' }

            # Do the concatenation...
            $x .= $y//q{};

            # Rebless as a precursor object...
            return bless {cooked=>$x, lexical_scope=>$lexical_scope}, 'Regexp::Debugger::Precursor';
        },

        # Using as a string (i.e. matching) preprocesses the precursor...
        q{""} => sub {
            my ($obj) = @_;

            use Scalar::Util qw< refaddr >;
            return $regex_cache{ refaddr($obj) }
                //= Regexp::Debugger::_build_debugging_regex( @{$obj}{'cooked', 'lexical_scope'} );
        },

        # Everything else, as usual...
        fallback => 1,
    );
}


#=====[ Augment a regex with debugging statements ]================


# Build code insertions for before and after elements in a regex...
# (the final $^R ensure these extra code blocks are "transparent")


sub _build_event {
    my ($regex_ID, $event_ID, $event_desc_ref) = @_;
    $event_desc_ref->{quantifier}  //= q{};
    $state{$regex_ID}{$event_ID} = $event_desc_ref;

    return qq{(?{Regexp::Debugger::_report_event($regex_ID, $event_ID, pos()); \$^R })(?=)};
}

sub _build_whitespace_event {
    my ($construct,$regex_ID, $event_ID, $event_desc_ref) = @_;
    $event_desc_ref->{quantifier}  //= q{};
    my %event_desc_copy = %{$event_desc_ref};
    $state{$regex_ID}{$event_ID}   = { %event_desc_copy, event_type => 'pre' };
    $state{$regex_ID}{$event_ID+1} = { %event_desc_copy, event_type => 'post', msg => 'Matched' };

    return qq{(?>(?{local \$Regexp::Debugger::prevpos=pos})$construct(?{
            if (defined \$Regexp::Debugger::prevpos && \$Regexp::Debugger::prevpos < pos){
                Regexp::Debugger::_report_event($regex_ID, $event_ID, \$Regexp::Debugger::prevpos);
                Regexp::Debugger::_report_event($regex_ID, $event_ID+1, pos());
            }\$^R })|(?{
                Regexp::Debugger::_report_event($regex_ID, $event_ID, pos());
            \$^R
            })(?!))};
}


# Translate lookaround markers...
my %LOOKTYPE = (
    '(?='  => 'positive lookahead',
    '(?!'  => 'negative lookahead',
    '(?<=' => 'positive lookbehind',
    '(?<!' => 'negative lookbehind',
);

sub _build_debugging_regex {
    my ( $raw_regex, $lexical_scope ) = @_;
    $lexical_scope //= 0;

    # How does this regexp show whitespace???
    our $show_ws = $config[$lexical_scope]{show_ws};

    # Build a clean, compacted version of the regex in this var...
    my $clean_regex = q{};

    # Track nested parentheticals so we can correctly mark each ')'...
    my @paren_stack = ( {} );

    # Give this regex a unique ID...
    my $regex_ID = $next_regex_ID++;

    # Remember raw data in case of over-eager quotemeta'ing...
    $state{$regex_ID}{raw_regex} = $raw_regex;

    # Remember location of regex...
    my ($filename, $end_line) = (caller 1)[1,2];
    my $regex_lines = $raw_regex =~ tr/\n//;
    my $start_line = $end_line - $regex_lines;
    $state{$regex_ID}{location}
        = $start_line == $end_line ? qq{'$filename' line $start_line}
                                   : qq{'$filename' lines $start_line-$end_line};

    # Track each inserted debugging statement...
    my $next_event_ID = 0;

    # Track capture groups...
    my $next_capture_group = 0;
    my $max_capture_group  = 0;

    # Track named capture aliases...
    my @capture_names_for;

    # Track \Q...\E
    my $in_quote = 0;
    my $shared_quote_pos;

    # Describe construct...
    our $construct_desc;
    our $quantifier_desc;

    # Translate each component...
    use re 'eval';
    $raw_regex =~ s{
        # Set-up...
        (?{ $quantifier_desc = q{}; $construct_desc = q{}; })

        # Match the next construct...
        (?<construct>
            (?<start>               \A   )
        |
            (?<end>                 \z   )
        |
            (?<quote_start>
                (??{!$Regexp::Debugger::in_quote ? q{} : q{(?!)} })
                \\Q
                (?{$Regexp::Debugger::in_quote = 1})
            )
        | (??{$Regexp::Debugger::in_quote ? q{} : q{(?!)} })
          (
            (?<quote_space>    \s++ )
          |
            (?<quote_end>      \\E  )
            (?{$Regexp::Debugger::in_quote = 0})
          |
            (?<quote_nonspace> \S   )
          )
        |
            (?<case_start>
                \\U   (?{$construct_desc = 'an auto-uppercased sequence'})
            |   \\L   (?{$construct_desc = 'an auto-lowercased sequence'})
            )
        |
            (?<case_end>
                \\E
            )
        |
            (?{$quantifier_desc = '';})
            (?<closing_paren>       [)]  )  (?<quantifier> (?&QUANTIFIER) )?
        |
            (?<whitespace>
                (?(?{ $show_ws eq 'compact' })
                    (?<whitespace_chars>
                        ( (?: \s | (?&COMMENT) )+ )
                        (?! (?&UNSPACED_QUANTIFIER) ) (?{ $quantifier_desc = q{} })
                        (?{$construct_desc = $^N})
                    |
                        ( \s )
                        (?{$construct_desc = $^N})
                        (?<quantifier> (?&UNSPACED_QUANTIFIER) )
                    )
                |
                    (?!)
                )
            |
                (?(?{ $show_ws eq 'visible' })
                    (?<whitespace_chars>
                        ( [^\S\n\t]+ )
                        (?! (?&UNSPACED_QUANTIFIER) ) (?{ $quantifier_desc = q{} })
                        (?{$construct_desc = $^N})
                    |
                        ( [^\S\n\t] )
                        (?{$construct_desc = $^N})
                        (?<quantifier> (?&UNSPACED_QUANTIFIER) )
                    )
                |
                    (?!)
                )
            |
                (?(?{ $show_ws eq 'original'})
                    (?<whitespace_chars>
                        ( [^\S\n\t] )
                        (?{$construct_desc = $^N})
                        (?<quantifier> (?&UNSPACED_QUANTIFIER) )?
                    )
                |
                    (?!)
                )
            |
                (?<newline_char>  \n  )
                (?<quantifier> (?&UNSPACED_QUANTIFIER) )?
                (?{$construct_desc = 'a literal newline character'})
            |
                (?<tab_char>      \t  )
                (?<quantifier> (?&UNSPACED_QUANTIFIER) )?
                (?{$construct_desc = 'a literal tab character'})
            )
        |
            (?<break_comment>
                [(][?][#] \s* (?i: BREAK ) \s* [)]
            )
        |
            (?<comment>
                (?&COMMENT)
            )
        |
            (?<modifier_set>
                [(] [?] (?&MODIFIERS) [)]
            )
        |
            (?<zero_width>
                (?<_anchor>
                    \^
                        (?{$construct_desc = 'at start of string (or line)'})
                |
                    \$
                        (?{$construct_desc = 'at end of string (or final newline)'})
                |
                    \\  (?:
                            A   (?{$construct_desc = 'at start of string'})
                        |
                            B   (?{$construct_desc = 'not at an identifier boundary'})
                        |
                            b   (?{$construct_desc = 'at an identifier boundary'})
                        |
                            G   (?{$construct_desc = 'at previous match position'})
                        |
                            Z   (?{$construct_desc = 'at end of string (or final newline)'})
                        |
                            z   (?{$construct_desc = 'at end of string'})
                        )
                )
            )
        |
            (?<matchable_code_block>
                [(] [?][?] (?&CODEBLOCK) [)]
            )
        |
            (?<code_block>
                [(] [?] (?&CODEBLOCK) [)]
            )
        |
            # Control verbs like (*PRUNE) and (*MARK:name)...
            (?<control>
                \(\* [[:upper:]]*+ (?: : [^)]++ )? \)
            )
        |
            (?<noncapturing_paren>     [(] [?] (?&MODIFIERS)? : )
        |
            (?<lookaround_paren>       [(] [?] [<]?[=!]         )
        |
            (?<non_backtracking_paren> [(] [?] [>]              )
            (?{$construct_desc = 'a non-backtracking group'})
        |
            (?<branch_reset_paren>     [(] [?] [|]              )
        |
            (?<capturing_paren>        [(] (?! [?])             )
        |
            (?<define_block>           [(] [?] [(] DEFINE [)]   )
        |
            (?<conditional_paren>
                [(] [?] [(]
                    (?<condition>
                        \d+
                    |   R  \d*
                    |   R& (?&IDENTIFIER)
                    |   < (?&IDENTIFIER) >
                    |   ' (?&IDENTIFIER) '
                    |   [?] (?&CODEBLOCK)
                    )
                [)]
            )
        |
            (?<conditional_paren> (?<pending_condition>
                [(] [?] (?= [(] [?] <? [=!] )
            ))
        |
            (?<named_capturing_paren>
                [(] [?] P? < (?<capture_name> (?&IDENTIFIER) ) >
              | [(] [?]    ' (?<capture_name> (?&IDENTIFIER) ) '
            )
        |
            (?<_alternation>        [|]  )
        |
            (?<keep_marker>         \\K  )
        |
            (?<atom>
                (?<_self_matching>  \w{2,}  )  (?! (?&QUANTIFIER) )
                (?{$quantifier_desc = ''; $construct_desc = qq{a literal sequence ("$+{_self_matching}")}})
            |
                (?{$quantifier_desc = '';})
                (?<_self_matching>  (?&NONMETA)   )  (?<quantifier> (?&QUANTIFIER) )?
                (?{$construct_desc = qq{a literal '$+{_self_matching}' character}})
            |
                (?{$quantifier_desc = '';})
                (?<_metacharacter>
                    [.]                             (?{$construct_desc = 'any character (except newline)'})
                |
                    \\
                    (?: (0[0-7]++)                  (?{$construct_desc = "a literal '".chr(oct($^N))."' character"})
                      | (\d++)                      (?{$construct_desc = "what was captured in \$$^N"})
                      | a                           (?{$construct_desc = 'an alarm/bell character'})
                      | c ([A-Z])                   (?{$construct_desc = "a CTRL-$^N character"})
                      | C                           (?{$construct_desc = 'a C-language octet'})
                      | d                           (?{$construct_desc = 'a digit'})
                      | D                           (?{$construct_desc = 'a non-digit'})
                      | e                           (?{$construct_desc = 'an escape character'})
                      | f                           (?{$construct_desc = 'a form-feed character'})
                      | g      (\d+)                (?{$construct_desc = "what was captured in \$$^N"})
                      | g    - (\d+)                (?{$construct_desc = $^N == 1 ? "what was captured by the nearest preceding capture group"
                                                                                  : "what was captured $^N capture groups back" })
                      | g \{   (\d+) \}             (?{$construct_desc = "what was captured in \$$^N"})
                      | g \{ - (\d+) \}             (?{$construct_desc = $^N == 1 ? "what was captured by the nearest preceding capture group"
                                                                                  : "what was captured $^N capture groups back" })
                      | g \{ (\w++) \}              (?{$construct_desc = "what the named capture <$^N> matched"})
                      | h                           (?{$construct_desc = 'a horizontal whitespace character'})
                      | H                           (?{$construct_desc = 'a non-horizontal-whitespace character'})
                      | k \< (\w++) \>              (?{$construct_desc = "what the named capture <$^N> matched"})
                      | n                           (?{$construct_desc = 'a newline character'})
                      | N \{ ([^\}]++) \}           (?{$construct_desc = "a single \L$^N\E character"})
                      | N                           (?{$construct_desc = 'a non-newline character'})
                      | p (\w++)                    (?{$construct_desc = "a character matching the Unicode property: $^N"})
                      | P (\w++)                    (?{$construct_desc = "a character not matching the Unicode property: $^N"})
                      | P \{ ([^\}]++) \}           (?{$construct_desc = "a character not matching the Unicode property: $^N"})
                      | p \{ ([^\}]++) \}           (?{$construct_desc = "a character matching the Unicode property: $^N"})
                      | r                           (?{$construct_desc = 'a return character'})
                      | R                           (?{$construct_desc = 'an end-of-line sequence'})
                      | S                           (?{$construct_desc = 'a non-whitespace character'})
                      | s                           (?{$construct_desc = 'a whitespace character'})
                      | t                           (?{$construct_desc = 'a tab character'})
                      | V                           (?{$construct_desc = 'a non-vertical-whitespace character'})
                      | v                           (?{$construct_desc = 'a vertical whitespace character'})
                      | w                           (?{$construct_desc = 'an identifier character'})
                      | W                           (?{$construct_desc = 'an non-identifier character'})
                      | x    ([0-9A-Za-z]++)        (?{$construct_desc = "a literal '".chr(oct('0x'.$^N))."' character"})
                      | x \{ ([0-9A-Za-z ]++) \}    (?{$construct_desc = "a literal '".chr(oct('0x'.$^N))."' character"})
                      | X                           (?{$construct_desc = 'a Unicode grapheme cluster'})
                      | (.)                         (?{$construct_desc = "a literal '$^N' character"})
                    )
                |
                    [(][?] P = (\w++) [)]    # PCRE version of \k<NAME>
                    (?{$construct_desc = "what the named capture <$^N> matched"})

                )  (?<quantifier> (?&QUANTIFIER) )?
            |
                (?{$quantifier_desc = '';})
                (?<_charset>  (?&CHARSET)  )  (?<quantifier> (?&QUANTIFIER) )?
                (?{$construct_desc = substr($+{_charset},0,2) eq '[^'
                                        ? 'any character not listed'
                                        : 'any of the listed characters'
                })
            |
                (?{$quantifier_desc = '';})
                (?<_named_subpattern_call>
                    [(][?]
                    (?:
                        [&] ((?&IDENTIFIER))   (?{$construct_desc = "a call to the subpattern named <$^N>"})
                    |   P>  ((?&IDENTIFIER))   (?{$construct_desc = "a call to the subpattern named <$^N>"})
                    |   [+]? (\d++)            (?{$construct_desc = 'a call to subpattern number $^N'})
                    |   [-]  (\d++)            (?{$construct_desc = $^N == 1 ? "a call to the nearest preceding subpattern"
                                                                             : "a call to the subpattern $^N back" })
                    |   R                      (?{$construct_desc = 'a recursive call to the current regex'})
                    )
                    [)]
                )
                (?<quantifier> (?&QUANTIFIER) )?
            )
        |
            (?<misc>        .    )
        )

    (?(DEFINE)
        # Miscellaneous useful pattern fragments...
        (?<COMMENT>    [(][?][#] (?! \s* BREAK \s* ) .*? [)] | \# [^\n]* (?= \n | \z )  )
        (?<CHARSET>    \[ \^?+ \\?+ \]?+ (?: \[:\w+:\] | \\[\[\]\\] | [^]] )*+ \] )
        (?<IDENTIFIER> [^\W\d]\w*                                   )
        (?<CODEBLOCK>  \{  (?: (?&CODEBLOCK) | . )*?   \}           )
        (?<MODIFIERS>  [adlupimsx]+ (?: - [imsx]+ )?
                    |  - [imsx]+
                    |  \^ [alupimsx]
        )
        (?<QUANTIFIER> \s* (?&UNSPACED_QUANTIFIER) )
        (?<UNSPACED_QUANTIFIER>
              [*][+]         (?{ $quantifier_desc = 'zero-or-more times (without backtracking)'          })
            | [*][?]         (?{ $quantifier_desc = 'zero-or-more times (as few as possible)'            })
            | [*]            (?{ $quantifier_desc = 'zero-or-more times (as many as possible)'           })
            | [+][+]         (?{ $quantifier_desc = 'one-or-more times (without backtracking)'           })
            | [+][?]         (?{ $quantifier_desc = 'one-or-more times (as few as possible)'             })
            | [+]            (?{ $quantifier_desc = 'one-or-more times (as many as possible)'            })
            | [?][+]         (?{ $quantifier_desc = 'one-or-zero times (without backtracking)'           })
            | [?][?]         (?{ $quantifier_desc = 'zero-or-one times (as few as possible)'             })
            | [?]            (?{ $quantifier_desc = 'one-or-zero times (as many as possible)'            })
            | {\d+,?\d*}[+]  (?{ $quantifier_desc = 'the specified number of times (without backtracking)' })
            | {\d+,?\d*}[?]  (?{ $quantifier_desc = 'the specified number of times (as few as possible)'   })
            | {\d+,?\d*}     (?{ $quantifier_desc = 'the specified number of times (as many as possible)'  })
        )
        (?<NONMETA>  [\w~`!%&=:;"'<>,/-] )
    )
    }{
        # Which event is this???
        my $event_ID = $next_event_ID++;

        # What are we debugging???
        my $construct = $+{construct};

        # How deep in parens???
        my $depth  = scalar(@paren_stack);
        my $indent = $INDENT x $depth;

        # All events get this standard information...
        my %std_info = (
            construct_type => (first { /^_/ } keys %+),
            construct      => $construct,
            regex_pos      => length($clean_regex),
            quantifier     => $+{quantifier} // q{},
            depth          => $depth,
            indent         => $indent,
        );

#        use Data::Dumper 'Dumper';
#        warn Dumper { std_info => \%std_info, '%+' => \%+ };

        # Record the construct for display...
        $clean_regex .=
               exists $+{newline_char}      ?  ($std_info{construct} = q{\n} . $std_info{quantifier})
             : exists $+{tab_char}          ?  ($std_info{construct} = q{\t} . $std_info{quantifier})
             : exists $+{whitespace_chars}  ?  ($std_info{construct} = q{ } . $std_info{quantifier})
             :                                 $construct
             ;

        # Determine and remember the necessary translation...
        my $translation = do {

            # Beginning and end of regex...
            if (exists $+{start}) {
                # Prime paren-tracking stack...
                push @paren_stack, {};

                # Insert an event to report (re-)starting...
                _build_event($regex_ID, $event_ID => {
                    %std_info,
                    construct_type => '_START',
                    event_type     => 'pre',
                    depth          => 1,
                    lexical_scope  => $lexical_scope,
                })
                . '(?:';
            }

            # At end of regex (if we get here, we matched)...
            elsif (exists $+{end}) {
                # Insert a final event to report successful match...
                ')'
                . _build_event($regex_ID, $event_ID => {
                    %std_info,
                    construct_type => '_END',
                    event_type     => 'post',
                    depth          => 1,
                    msg            => sub { my $steps = @{$history_of{visual}};
                                            "Regex matched in $steps step" . ($steps != 1 ? 's' : '');
                                      },
                })
                . '|'
                . _build_event($regex_ID, $event_ID+1 => {
                    %std_info,
                    construct_type => '_END',
                    event_type     => 'post',
                    regex_failed   => 1,
                    depth          => 1,
                    msg            => sub { my $steps = @{$history_of{visual}};
                                            "Regex failed to match after $steps step" . ($steps != 1 ? 's' : '');
                                      },
                })
                . '(?!)';
            }

            # Alternatives marked by a |...
            elsif (exists $+{_alternation}) {
                # Reset capture numbers if in reset group...
                if (my $reset = $paren_stack[-1]{is_branch_reset}) {
                    $next_capture_group = $reset-1;
                }

                # We need two events, so add an extra one...
                $event_ID = $next_event_ID++;

                # Insert events to indicate which side of the | we're trying now...
                  _build_event($regex_ID, $event_ID-1 => {
                        %std_info,
                        event_type => 'end',
                        msg        => 'End of successful alternative',
                        desc       => 'Or...',
                        indent     => $INDENT x ($depth-1),
                  })
                . $construct
                . _build_event($regex_ID, $event_ID => {
                        %std_info,
                        event_type => 'start',
                        msg        => 'Trying next alternative',
                  })
            }

            # Whitespace has to be treated specially (because it may or may not be significant...
            elsif (exists $+{whitespace}) {
                # The two events communicate privately via this variable...
                my $shared_str_pos;

                # Two events required, so add an extra ID...
                $next_event_ID++;

                $construct_desc = join q{}, map { $_ eq "\n" ? '\n'
                                                : $_ eq "\t" ? '\t'
                                                : $_ eq " "  ? '\N{SPACE}'
                                                :               $_
                                                } split '', $construct_desc;

                # Insert the appropriate events...
                _build_whitespace_event($construct, $regex_ID, $event_ID => {
                        %std_info,
                        matchable      => 1,
                        msg            => "Trying literal whitespace ('$construct_desc') $quantifier_desc",
                        shared_str_pos => \$shared_str_pos,
                })
            }

            # \L and \U start case-shifted sequences...
            elsif (exists $+{case_start}) {
                  _build_event($regex_ID, $event_ID => {
                        %std_info,
                        event_type => 'pre',
                        msg        => "Starting $construct_desc",
                        desc       => 'The start of ' . $construct_desc,
                  })
            }

            elsif (exists $+{case_end}) {
                  _build_event($regex_ID, $event_ID => {
                        %std_info,
                        event_type => 'pre',
                        msg        => 'End of autocasing',
                        desc       => 'The end of autocasing',
                  })
            }

            # \Q starts a quoted sequence...
            elsif (exists $+{quote_start}) {
                # Set up communication channel between \Q and \E...
                my $shared_pos;
                $shared_quote_pos = \$shared_pos;

                  _build_event($regex_ID, $event_ID => {
                        %std_info,
                        event_type     => 'pre',
                        msg            => 'Starting quoted sequence',
                        desc           => 'The start of a quoted sequence',
                        shared_str_pos => $shared_quote_pos,
                  })
            }

            # \E ends a quoted sequence...
            elsif (exists $+{quote_end}) {
                # Retrieve communication channel between \Q and \E...
                my $shared_pos = $shared_quote_pos;
                $shared_quote_pos = undef;

                  _build_event($regex_ID, $event_ID => {
                        %std_info,
                        event_type     => 'post',
                        msg            => 'End of quoted sequence',
                        desc           => 'The end of a quoted sequence',
                        shared_str_pos => $shared_pos,
                  })
            }


            # Quoted subsequences...
            elsif (exists $+{quote_space}) {
                # The two events communicate privately via this variable...
                my $shared_str_pos;

                # Two events, so add an extra ID...
                $event_ID = $next_event_ID++;

                  _build_event($regex_ID, $event_ID-1 => {
                        %std_info,
                        matchable      => 1,
                        event_type     => 'pre',
                        msg            => 'Trying autoquoted literal whitespace',
                        shared_str_pos => \$shared_str_pos,
                  })
                . quotemeta($construct)
                . _build_event($regex_ID, $event_ID => {
                        %std_info,
                        matchable      => 1,
                        event_type     => 'post',
                        msg            => 'Matched autoquoted literal whitespace',
                        shared_str_pos => \$shared_str_pos,
                  })
            }

            elsif (exists $+{quote_nonspace}) {
                # The two events communicate privately via this variable...
                my $shared_str_pos;

                # Two events, so add an extra ID...
                $event_ID = $next_event_ID++;

                  _build_event($regex_ID, $event_ID-1 => {
                        %std_info,
                        matchable      => 1,
                        event_type     => 'pre',
                        msg            => 'Trying an autoquoted literal character',
                        desc           => 'Match an autoquoted literal character',
                        shared_str_pos => \$shared_str_pos,
                  })
                . quotemeta($construct)
                . _build_event($regex_ID, $event_ID => {
                        %std_info,
                        matchable      => 1,
                        event_type     => 'post',
                        msg            => 'Matched a literal character',
                        shared_str_pos => \$shared_str_pos,
                  })
            }

            # Atoms are any elements that match and emit debugging info before and after matching...
            elsif (exists $+{atom}) {
                # The two events communicate privately via this variable...
                my $shared_str_pos;

                # Track depth of subpattern calls...
                my $is_subpattern_call = exists $+{_named_subpattern_call};
                my $subpattern_call_prefix
                    = $is_subpattern_call
                        ? q{(?{local $Regexp::Debugger::subpattern_depth = $Regexp::Debugger::subpattern_depth + 1})}
                        : q{};
                my $subpattern_call_suffix
                    = $is_subpattern_call
                        ? q{(?{local $Regexp::Debugger::subpattern_depth = $Regexp::Debugger::subpattern_depth - 1})}
                        : q{};

                # Two events, so add an extra ID...
                $event_ID = $next_event_ID++;
                  _build_event($regex_ID, $event_ID-1 => {
                        %std_info,
                        matchable      => 1,
                        event_type     => 'pre',
                        msg            => "Trying $construct_desc" . (length($quantifier_desc) ? ", $quantifier_desc" : q{}),
                        desc           => "Match $construct_desc" . (length($quantifier_desc) ? ", $quantifier_desc" : q{}),
                        shared_str_pos => \$shared_str_pos,
                  })
                . $subpattern_call_prefix
                . $construct
                . $subpattern_call_suffix
                . _build_event($regex_ID, $event_ID => {
                        %std_info,
                        matchable      => 1,
                        event_type     => 'post',
                        msg            => 'Matched'
                                        . ($is_subpattern_call ? " (discarding subpattern's captures)": q{}),
                        shared_str_pos => \$shared_str_pos,
                  })
            }

            # Code blocks (?{...})...
            elsif (exists $+{code_block}) {
                # Add an event beforehand to indicate execution of the block...
                  _build_event($regex_ID, $event_ID => {
                        %std_info,
                        matchable  => 0,
                        event_type => 'action',
                        msg        => 'Executing code block',
                        desc       => 'Execute a block of code',
                  })
                . $construct
            }

            # Code blocks that generate dynamic patterns (??{...})...
            elsif (exists $+{matchable_code_block}) {
                # These events communicate privately via this variable...
                my $shared_str_pos;

                # Modify construct to generate but not match...
                substr($construct, 1, 1) = q{};

                # Inserting three events, so add an extra two IDs...
                $event_ID = ($next_event_ID+=3);
                  # First event pair reports executing the block...
                  _build_event($regex_ID, $event_ID-4 => {
                        %std_info,
                        matchable  => 0,
                        event_type => 'action',
                        msg        => 'Executing code block of postponed subpattern',
                        desc       => "Execute a code block, then match the block's final value",
                  })
                . $construct
                . _build_event($regex_ID, $event_ID-3 => {
                        %std_info,
                        matchable  => 0,
                        event_type => 'action',
                        msg        => sub { "Code block returned: '$^R'" },
                  })
                  # Second event pair reports match of subpattern the block returned...
                . _build_event($regex_ID, $event_ID-2 => {
                        %std_info,
                        matchable      => 1,
                        event_type     => 'pre',
                        msg            => sub{ "Trying: qr{$^R}" },
                        shared_str_pos => \$shared_str_pos,
                  })
                . '(??{ $^R })'
                . _build_event($regex_ID, $event_ID-1 => {
                        %std_info,
                        matchable      => 1,
                        event_type     => 'post',
                        msg            => 'Matched',
                        shared_str_pos => \$shared_str_pos,
                  })
            }

            # Keep marker...
            elsif (exists $+{keep_marker}) {
                # Insert events reporting testing the assertion, and if the test succeeds...
                  _build_event($regex_ID, $event_ID => {
                        %std_info,
                        matchable  => 0,
                        event_type => 'action',
                        msg        => "Forgetting everything matched to this point",
                        desc       => 'Pretend the final match starts here',
                  })
                . $construct
                . '(?{ local $Regexp::Grammars::match_start_pos = pos() })'
            }

            # Zero-width assertions...
            elsif (exists $+{zero_width}) {
                # Two events, so add an extra ID...
                $event_ID = $next_event_ID++;

                # Insert events reporting testing the assertion, and if the test succeeds...
                  _build_event($regex_ID, $event_ID-1 => {
                        %std_info,
                        matchable  => 1,
                        event_type => 'pre',
                        msg        => "Testing if $construct_desc",
                        desc       => "Match only if $construct_desc",
                  })
                . $construct
                . _build_event($regex_ID, $event_ID => {
                        %std_info,
                        matchable  => 1,
                        event_type => 'post',
                        msg        => 'Assertion satisfied',
                  })
            }

            # Control verbs: (*PRUNE) (*SKIP) (*FAIL) etc...
            elsif (exists $+{control}) {
                # Two events, so add an extra ID...
                $event_ID = $next_event_ID++;

                # Insert events to report both the attempt and its success...
                  _build_event($regex_ID, $event_ID-1 => {
                        %std_info,
                        matchable  => 1,
                        event_type => 'pre',
                        msg        => 'Executing a control',
                        desc       => 'Execute a backtracking control',
                  })
                . $construct
                . _build_event($regex_ID, $event_ID => {
                        %std_info,
                        matchable  => 1,
                        event_type => 'post',
                        msg        => 'Control succeeded',
                  })
            }

            # Start of DEFINE block...
            elsif (exists $+{define_block}) {
                # It's an unbalanced opening paren, so remember it on the stack...
                push @paren_stack, {
                    is_capture     => 0,
                    construct_type => '_DEFINE_block',
                    is_definition  => 1,
                };

                # Insert and event to report skipping the entire block...
                _build_event($regex_ID, $event_ID => {
                        %std_info,
                        %{$paren_stack[-1]},
                        matchable  => 0,
                        event_type => 'pre',
                        msg        => 'Skipping definitions',
                        desc       => 'The start of a definition block (skipped during matching)',
                  })
                . $construct . '(?:'
            }

            # Modifier set: (?is-mx) etc...
            elsif (exists $+{modifier_set}) {
                # Insert an event to report the change of active modifiers...
                _build_event($regex_ID, $event_ID => {
                        %std_info,
                        %{$paren_stack[-1]},
                        matchable  => 0,
                        event_type => 'compile',
                        msg        => 'Changing modifiers',
                        desc       => 'Change current modifiers',
                  })
                . $construct
            }

            # Conditional parens: (?(COND) X | Y )...
            elsif (exists $+{conditional_paren}) {
                # It's an unbalanced opening paren, so remember it on the stack...
                push @paren_stack, {
                    is_capture      => 0,
                    is_conditional  => 1,
                    is_pending      => exists $+{pending_condition}, # ...expecting a lookahead?
                    construct_type  => '_conditional_group',
                };

                # Insert an event to report the test...
                  '(?:'
                . _build_event($regex_ID, $event_ID => {
                    %std_info,
                    %{$paren_stack[-1]},
                    event_type => 'pre',
                    msg        => 'Testing condition',
                    desc       => 'The start of a conditional block',
                  })
                . $construct;
            }

            # Branch-reset parens...
            elsif (exists $+{branch_reset_paren}) {
                # It's an unbalanced opening paren, so remember it on the stack...
                push @paren_stack, {
                    is_capture      => 0,
                    is_branch_reset => $next_capture_group+1,
                    construct_type  => '_branch_reset_group',
                };

                # Insert an event to report the start of branch-reseting...
                  '(?:'
                . _build_event($regex_ID, $event_ID => {
                    %std_info,
                    %{$paren_stack[-1]},
                    event_type => 'pre',
                    msg        => 'Starting branch-resetting group',
                    desc       => 'The start of a branch-resetting group',
                  })
                . $construct;
            }

            # Non-capturing parens...
            elsif (exists $+{noncapturing_paren}) {
                # Do the non-capturing parens have embedded modifiers???
                my $addendum = length($construct) > 3 ? ', changing modifiers' : q{};

                # It's an unbalanced opening paren, so remember it on the stack...
                push @paren_stack, {
                    is_capture     => 0,
                    construct_type => '_noncapture_group',
                };

                # Insert an event to report the start of a non-capturing group...
                  '(?:'
                . _build_event($regex_ID, $event_ID => {
                    %std_info,
                    %{$paren_stack[-1]},
                    event_type => 'pre',
                    msg        => 'Starting non-capturing group' . $addendum,
                    desc       => 'The start of a non-capturing group',
                  })
                . $construct;
            }

            # Non-backtracking parens...
            elsif (exists $+{non_backtracking_paren}) {
                # It's an unbalanced opening paren, so remember it on the stack...
                push @paren_stack, {
                    is_capture      => 0,
                    is_nonbacktrack => 1,
                    construct_type  => '_nonbacktracking_group',
                };

                # Insert an event to report the start of a non-backtracking group...
                  '(?:'
                . _build_event($regex_ID, $event_ID => {
                    %std_info,
                    %{$paren_stack[-1]},
                    event_type => 'pre',
                    msg        => 'Starting non-backtracking group',
                    desc       => 'The start of a non-backtracking group',
                  })
                . '(?>';
            }

            # Positive lookahead/lookbehind parens...
            elsif (exists $+{lookaround_paren}) {
                # It's an unbalanced opening paren, so remember it on the stack...
                push @paren_stack, {
                    is_capture     => 0,
                    is_lookaround  => $LOOKTYPE{$construct},
                    construct_type => '_lookaround',
                };

                # Is this lookaround the test of a (?(COND) X | Y) conditional???
                if ($paren_stack[-2]{is_conditional} && $paren_stack[-2]{is_pending}) {
                    # If so, the test is no longer pending...
                    delete $paren_stack[-2]{is_pending};

                    # Insert an event to report the test...
                      $construct
                    . '(?:'
                    . _build_event($regex_ID, $event_ID => {
                        %std_info,
                        %{$paren_stack[-1]},
                        event_type => 'pre',
                        msg        => 'Testing for ' . $LOOKTYPE{$construct},
                        desc       => 'Match ' . lc $LOOKTYPE{$construct},
                    });
                }
                else {
                    # Otherwise, insert an event to report the start of the lookaround...
                    '(?:'
                    . _build_event($regex_ID, $event_ID => {
                        %std_info,
                        %{$paren_stack[-1]},
                        event_type => 'pre',
                        msg        => 'Starting ' . $LOOKTYPE{$construct},
                        desc       => 'Match ' . $LOOKTYPE{$construct},
                    })
                    . $construct;
                }
            }

            # Capturing parens...
            elsif (exists $+{capturing_paren}) {
                # The events communicate privately via this variable...
                my $shared_str_pos;

                # Get the corresponding capture group number...
                $next_capture_group++;

                # Track the maximum group number (for after branch resets)...
                $max_capture_group = max($max_capture_group, $next_capture_group);

                # It's an unbalanced opening paren, so remember it on the stack...
                push @paren_stack, {
                    is_capture     => 1,
                    construct_type => '_capture_group',
                    capture_name   => '$'.$next_capture_group,
                    shared_str_pos => \$shared_str_pos,
                };

                # Insert an event to report the start of capturing...
                  '('
                . _build_event($regex_ID, $event_ID => {
                    %std_info,
                    %{$paren_stack[-1]},
                    event_type => 'pre',
                    msg        => 'Capture to $'.$next_capture_group,
                    desc       => "The start of a capturing block (\$$next_capture_group)",
                  })
                . '(?:';
            }

            # Named capturing parens...
            elsif (exists $+{named_capturing_paren}) {
                # The events communicate privately via this variable...
                my $shared_str_pos;

                # Named capture groups are also numbered, so get the number...
                $next_capture_group++;

                # Track the maximum group number (for after branch resets)...
                $max_capture_group = max($max_capture_group, $next_capture_group);

                # If this creates a new numbered capture, remember the number...
                if (!@{$capture_names_for[$next_capture_group]//[]}) {
                    push @{$capture_names_for[$next_capture_group]}, '$'.$next_capture_group;
                }

                # Add this name to the list of aliases for the same numbered capture...
                # (Needed because named captures in two reset branches may alias
                # to the same underlying numbered capture variable. See perlre)
                push @{$capture_names_for[$next_capture_group]}, '$+{'.$+{capture_name}.'}';

                # It's an unbalanced opening paren, so remember it on the stack...
                push @paren_stack, {
                    is_capture     => 1,
                    construct_type => '_capture_group',
                    capture_name   => $capture_names_for[$next_capture_group],
                    shared_str_pos => \$shared_str_pos,
                };

                # Insert an event to report the start of the named capture...
                  $construct
                . _build_event($regex_ID, $event_ID => {
                    %std_info,
                    %{$paren_stack[-1]},
                    event_type => 'pre',
                    msg        => $capture_names_for[$next_capture_group],
                    desc       => "The start of a named capturing block (also \$$next_capture_group)",
                  })
                . '(?:';
            }

            # Closing parens have to be deciphered...
            elsif (exists $+{closing_paren}) {
                # The top of the paren stack tells us what kind of group we're closing...
                my $paren_data = pop(@paren_stack) // { type=>'unmatched closing )' };

                # Update the next capture group number, if after a branch reset group...
                if ($paren_data->{is_branch_reset}) {
                    $next_capture_group = $max_capture_group;
                }

                # Generate an appropriate message for the type of group being closed...
                my $msg = $paren_data->{is_capture} && ref $paren_data->{capture_name}
                                                         ? $paren_data->{capture_name}
                        : $paren_data->{is_capture}      ? 'End of ' . $paren_data->{capture_name}
                        : $paren_data->{is_definition}   ? 'End of definition block'
                        : $paren_data->{is_branch_reset} ? 'End of branch-resetting group'
                        : $paren_data->{is_lookaround}   ? 'End of ' . $paren_data->{is_lookaround}
                        : $paren_data->{is_conditional}  ? 'End of conditional group'
                        : $paren_data->{is_nonbacktrack} ? 'End of non-backtracking group'
                        :                                  'End of non-capturing group'
                        ;

                if (length($std_info{quantifier})) {
                    $msg .= " (matching $quantifier_desc)";
                }

                # Two events, so add an extra ID...
                $event_ID = $next_event_ID++;

                # Append an event reporting the completion of the group...
                  ')'
                . _build_event($regex_ID, $event_ID-1 => {
                    %std_info,
                    %{$paren_data},
                    event_type => 'post',
                    msg        => $msg,
                    desc       => ( ref $msg ? 'The end of the named capturing block' : 'The e' . substr($msg,1) ),
                    depth      => $depth - 1,
                    indent     => $INDENT x ($depth - 1),
                  })
                . ($paren_data->{is_nonbacktrack}
                        ? '|'
                        . _build_event($regex_ID, $event_ID => {
                            %std_info,
                            %{$paren_data},
                            event_type => 'failed_nonbacktracking',
                            msg        => 'non-backtracking group',
                            depth      => $depth - 1,
                            indent     => $INDENT x ($depth - 1),
                          })
                        . q{(?!)}
                        : q{}
                  )
                . ')'
                . $std_info{quantifier};
            }

            # Skip comments...
            elsif (exists $+{break_comment}) {
                # Insert an event reporting that the break comment is being skipped...
                _build_event($regex_ID, $event_ID => {
                        %std_info,
                        %{$paren_stack[-1]},
                        matchable  => 0,
                        event_type => 'break',
                        msg        => 'Breaking at (and skipping) comment',
                        desc       => 'Ignore this comment (but Regexp::Debugger will break here)',
                  })
            }

            # Skip comments...
            elsif (exists $+{comment}) {
                # Insert an event reporting that the comment is being skipped...
                _build_event($regex_ID, $event_ID => {
                        %std_info,
                        %{$paren_stack[-1]},
                        matchable  => 0,
                        event_type => 'skip',
                        msg        => 'Skipping comment',
                        desc       => 'Ignore this comment',
                  })
            }

            # Ignore (but preserve) anything else...
            else {
                $construct;
            }
        };
    }exmsg;

    # Remember the regex...
    $state{$regex_ID}{regex_src} = $clean_regex;

    # Add a preface to reset state variables in the event handler...
    $raw_regex = "(?>\\A(?{Regexp::Debugger::_reset_debugger_state()})(?!))|(?:$raw_regex)";

    return "(?#R_d:$regex_ID)".$raw_regex;
}

#====[ Dispatch in-regex events ]================================

# How big the display window is...
my $MAX_WIDTH  = 80;
my $MAX_HEIGHT = 60;

# What to print so as to "clear" the screen...
my $CLEAR_SCREEN = "\n" x $MAX_HEIGHT;

# How wide is each column in event mode...
my $EVENT_COL_WIDTH = 15;


sub _show_if_active {
    my ($data_mode, $display_mode, $event_desc) = @_;

    # Accumulate history...
    my $history_to_date
        = @{$history_of{$data_mode}//[]} ? $history_of{$data_mode}[-1]{display} : q{};

    # Remember, always....
    push @{$history_of{$data_mode}}, {
        display => $history_to_date . $event_desc . "\n"
    };

    # Show, if appropriate...
    if ($display_mode eq $data_mode) {
        if (!$lexical_config->{save_to_fh} || $data_mode ne 'JSON') {
            _print $CLEAR_SCREEN;
            _say $history_of{$data_mode}[-1]{display};
        }
    }

}

sub _show_JSON    { _show_if_active('JSON',    @_) }
sub _show_event   { _show_if_active('events',  @_) }


# Add a new animation "frame"...
sub _new_visualize {
    my ($data_mode) = @_;
    push @{$history_of{$data_mode}}, { display=>q{}, is_match => 0 };
}

# Output the args and also add them to the current animation "frame"
sub _visualize {
    my ($data_mode, @output) = @_;
    state $NO_MATCH = 0;
    state $NO_FAIL  = 0;
    _visualize_matchfail($data_mode, $NO_MATCH, $NO_FAIL, @output);
}

sub _visualize_matchfail {
    my ($data_mode, $is_match, $is_fail, @output) = @_;
    my $output = join q{}, grep {defined} @output;
    if ($display_mode eq $data_mode) {
        _say $output;
    }
    $history_of{$data_mode}[-1]{is_fail}   = 1 if $is_fail;
    $history_of{$data_mode}[-1]{is_match}  = 1 if $is_match;
    $history_of{$data_mode}[-1]{display}  .= $output . "\n";
}

# Show previous animation frames...
sub _revisualize {
    my ($regex_ID, $step) = @_;

    # Start at the previous step unless otherwise specified...
    $step //= max(0, @{$history_of{$display_mode}}-2);

    my $input = '-';
    STEP:
    while (1) {
        # Did we fall out of available history???
        last STEP if $step >= @{$history_of{$display_mode}};

        # Clear display and show the requested step...
        if ($input ne '?') {
            _print $CLEAR_SCREEN;
            _print $history_of{$display_mode}[$step]{display};
            if ($display_mode eq 'events' || $display_mode eq 'JSON') {
                if (!$lexical_config->{save_to_fh}) {
                    say _info_colourer(
                        qq{\n\n[\u$display_mode of regex at $state{$regex_ID}{location}]}
                      . qq{         [step: $step]}
                    );
                }
            }
        }

        # Next input (but use starting cmd if one given)...
        $input = _interact();

        # A <CTRL-C> terminates the process...
        if ($input eq "\cC") {
            kill 9, $$;
        }

        # An 'x' exits the process...
        elsif ($input eq 'x') {
            exit(0);
        }

        # A <CTRL-L> redraws the screen...
        elsif ($input eq "\cL") {
            next STEP;
        }

        # Step back (if possible)...
        elsif ($input eq '-') {
            $step = max(0, $step-1);
            next STEP;
        }

        # Display explanation of regex...
        elsif ($input eq 'd') {
            _show_regex_description($regex_ID);
            next STEP;
        }

        # Help!
        elsif ($input eq '?') {
            _show_help();
            next STEP;
        }

        # Swap to requested mode...
        elsif ($input eq 'v') {
            $display_mode = 'visual';
            next STEP;
        }
        elsif ($input eq 'h') {
            # Can we use heatmap mode?
            if ($heatmaps_invisible) {
                say 'Cannot show heatmaps (Term::ANSIColor unavailable)';
                say "Try 'H' instead";
                $input = '?';
            }
            # If heatmaps available, check for misuse of 'h' instead of '?'...
            else {
                my $prompt_help = $display_mode eq 'heatmap';
                $display_mode = 'heatmap';
                if ($prompt_help) {
                    say "(Type '?' for help)";
                }
            }
            next STEP;
        }
        elsif ($input eq 'e') {
            $display_mode = 'events';
            say _info_colourer(
                qq{\n\n[Events of regex at $state{$regex_ID}{location}]}
              . qq{         [step: $step]}
            );
            next STEP;
        }
        elsif ($input eq 'j') {
            $display_mode = 'JSON';
            next STEP;
            say _info_colourer(
                qq{\n\n[JSON data of regex at $state{$regex_ID}{location}]}
              . qq{         [step: $step]}
            );
        }

        # Continue with actual matching...
        elsif ($input eq 'c') {
            while ($step < @{$history_of{$display_mode}}) {
                _print $CLEAR_SCREEN;
                _print $history_of{$display_mode}[$step++]{display};
                _pause(0.1);
            }
            last STEP;
        }

        # Quit entirely...
        elsif ($input eq 'q' || $input eq "\cD") {
            last STEP;
        }

        # Take a snapshot...
        elsif ($input eq 'V') { _save_snapshot('full_visual',  $step)     ; next STEP; }
        elsif ($input eq 'H') { _save_snapshot('full_heatmap', $step)     ; next STEP; }
        elsif ($input eq 'E') { _save_snapshot('events',       $step)     ; next STEP; }
        elsif ($input eq 'J') { _save_snapshot('JSON',         $step)     ; next STEP; }
        elsif ($input eq 'D') { _show_regex_description($regex_ID,'save') ; next STEP; }

        # Step forward to match...
        elsif ($input eq 'm') {
            $step++;
            while (!$history_of{$display_mode}[$step]{is_match}) {
                last STEP if $step == @{$history_of{$display_mode}}-1;
                $step++;
            }
        }

        # Step forward to fail...
        elsif ($input eq 'f') {
            $step++;
            while (!$history_of{$display_mode}[$step]{is_fail}) {
                last STEP if $step == @{$history_of{$display_mode}}-1;
                $step++;
            }
        }
        # Otherwise just step forward...
        else {
            $step++;
        }
    }

    # Return final command...
    return ($input, $step);
}

sub _build_visualization {
    # Unpack all the info needed...
    my ($data_mode, $named_args_ref) = @_;

    my ($regex_ID, $regex_src, $regex_pos, $construct_len,
        $str_src, $str_pos,
        $is_match, $is_fail, $is_trying, $is_capture,
        $backtrack, $forward_step, $nested_because,
        $msg, $colourer, $no_window, $step)
                = @{$named_args_ref}{qw(
                    regex_ID regex_src regex_pos construct_len
                    str_src str_pos
                    is_match is_fail is_trying is_capture
                    backtrack forward_step nested_because
                    msg colourer no_window step
                )};

    # Clear screen...
    _new_visualize($data_mode);
    if (!$no_window) {
        _visualize $data_mode, q{} for 1..$MAX_HEIGHT;
    }

    # Remember originals...
    my $raw_str_src   = $str_src;
    my $raw_regex_src = $regex_src;

    # Unwindowed displays show the title first...
    if ($no_window) {
        _visualize $data_mode,
                _info_colourer(
                    qq{\n[\u$data_mode of regex at $state{$regex_ID}{location}]\n\n}
                  . qq{         [step: $step]}
                );
    }

    # Visualize capture vars, if available...
    my $max_name_width = 1 + max map {length} 0, keys %capture;
    CAPVAR:
    for my $name (do{ no warnings 'numeric'; sort { substr($a,1) <=> substr($b,1) } keys %capture}) {
        # Remove any captures that are invalidated by backtracking...
        if ($capture{$name}{start_pos} > $regex_pos) {
            delete @{$capture{$name}}{'from','to'};
        }

        # Clean up and visualize each remaining variable...
        my $start   = $capture{$name}{from} // next CAPVAR;
        my $end     = $capture{$name}{to}   // next CAPVAR;
        my $cap_str = _quote_ws(substr($_,$start,$end-$start));

        # Truncate captured value to maximum width by removing middle...
        my $cap_len = length($cap_str);
        if ($cap_len > $MAX_WIDTH) {
            my $middle = $MAX_WIDTH/2 - 2;
            substr($cap_str, $middle, -$middle, '....');
        }

        # Display capture var and value...
        _visualize $data_mode,
            _info_colourer(sprintf qq{%*s = '%s'}, $max_name_width, $name, $cap_str);
    }

    # Visualize special var, if used in regex...
    _visualize $data_mode, q{};
    if (index($raw_regex_src, '$^N') >= 0 && defined $^N) {
        my $special_val = $^N;

        # Truncate captured value to maximum width by removing middle...
        my $cap_len = length($special_val);
        if ($cap_len > $MAX_WIDTH) {
            my $middle = $MAX_WIDTH/2 - 2;
            substr($special_val, $middle, -$middle, '....');
        }

        # Display capture var and value...
        _visualize $data_mode,
            _info_colourer(sprintf qq{%*s = '%s'}, $max_name_width, '$^N', $special_val);
    }

    # Leave a gap...
    _visualize $data_mode, q{} for 1..2;

    # Show matching...
    _visualize_matchfail $data_mode, $is_match, $is_fail;

    # Reconfigure regex within visible window...
    ($regex_src, $regex_pos)
        = _make_window(
                 text => $regex_src,
                  pos => $regex_pos,
                 heat => substr($data_mode, -7) eq 'heatmap' ?  $history_of{match_heatmap} : [],
            ws_colour => substr($data_mode, -7) eq 'heatmap',
            no_window => $no_window,
        );

    # How wide is the display???
    my $display_width
        = $no_window ? $regex_pos
        :              min($regex_pos, $MAX_WIDTH - length($msg));

    # Draw the regex with a message and a positional marker...
    if ($data_mode ne 'full_heatmap') {
        _visualize $data_mode, q{ }, q{ } x $display_width, $colourer->($msg);
        _visualize $data_mode, q{ }, q{ } x $regex_pos    , $colourer->('|');
        _visualize $data_mode, q{ }, q{ } x $regex_pos    , $colourer->('V') x ($construct_len || 1);
    }
    else {
        _visualize $data_mode, q{ }, q{ } x $regex_pos , _info_colourer('|');
        _visualize $data_mode, q{ }, q{ } x $regex_pos , _info_colourer('V' x ($construct_len || 1) );
    }

    # Draw regex itself...
    _visualize $data_mode, q{/}, $regex_src, q{/};

    # Leave a gap...
    _visualize $data_mode, q{ } for 1..2;

    # Create marker for any match or capture within string...
    $forward_step = min($forward_step, $MAX_WIDTH);
    my $last_match_marker
        = (q{ } x ($str_pos - max(0,$forward_step)))
        . ( $nested_because eq 'failed'       ? q{}
          : $is_capture && $forward_step == 1 ? 'V'
          : $is_capture && $forward_step > 1  ? '\\' . ('_' x ($forward_step-2)) . '/'
          :                                      '^' x $forward_step
          )
        ;


    # Reconfigure string within visible window...
    my $match_start;
    ($str_src, $str_pos, $match_start, $last_match_marker)
        = _make_window(
                 text => $str_src,
                  pos => $str_pos,
                start => $Regexp::Grammars::match_start_pos,
                 heat => substr($data_mode, -7) eq 'heatmap' ?  $history_of{string_heatmap} : [],
            ws_colour => substr($data_mode, -7) eq 'heatmap',
               marker => $last_match_marker,
            no_window => $no_window,
          );

    # Trim match start position...
    if ($match_start > $str_pos) {
        $match_start = $str_pos;
    }

    # Colour match marker...
    $last_match_marker
        = substr($last_match_marker,0,1) eq '^' ? _match_colourer($last_match_marker, 'reverse')
        :                                         _info_colourer($last_match_marker);

    # Draw the string with a positional marker...
    _visualize $data_mode,
        q{ }, _info_colourer( substr(q{ } x $str_pos . '|' .  $backtrack, 0, $MAX_WIDTH-2) );
    _visualize $data_mode,
        q{ }, q{ } x $match_start, _match_colourer($MATCH_DRAG x ($str_pos-$match_start)), _info_colourer('V');
    $str_src = # Heatmap is already coloured...
               substr($data_mode, -7) eq 'heatmap' ?
                    $str_src

               # On failure, fail-colour to current position...
             : $nested_because eq 'failed' ?
                    _fail_colourer( substr($str_src, 0, $str_pos), 'ws' )
                  . _ws_colourer(   substr($str_src, $str_pos)          )

               # When trying, try-colour current position
             : $is_trying ?
                    _fail_colourer(  substr($str_src, 0, $match_start),                                  'ws' )
                  . _match_colourer( substr($str_src, $match_start, $str_pos-$match_start), 'underline', 'ws' )
                  . _try_colourer(   substr($str_src, $str_pos, 1), 'underline bold',                    'ws' )
                  . _ws_colourer(    substr($str_src, min(length($str_src),$str_pos+1))                       )

             : # Otherwise, report pre-failure and current match...
                    _fail_colourer(  substr($str_src, 0, $match_start),                                  'ws' )
                  . _match_colourer( substr($str_src, $match_start, $str_pos-$match_start), 'underline', 'ws' )
                  . _ws_colourer(    substr($str_src, $str_pos)                                               );

    _visualize $data_mode, q{'}, $str_src, q{'};  # String itself

    # Draw a marker for any match or capture within the string...
    _visualize $data_mode, q{ }, $last_match_marker;

    # Windowed displays show the title last...
    if (!$no_window) {
        _visualize $data_mode,
                _info_colourer(
                    qq{\n[\u$data_mode of regex at $state{$regex_ID}{location}]}
                  . qq{         [step: $step]}
                );
    }

    # Special case: full heatmaps are reported as a table too...
    if ( $data_mode eq 'full_heatmap' ) {
        # Tabulate regex...
        _visualize $data_mode, _info_colourer("\n\nHeatmap for regex:\n");
        _visualize $data_mode, _build_tabulated_heatmap($raw_regex_src, $history_of{match_heatmap});

        # Tabulate string...
        _visualize $data_mode, _info_colourer("\n\nHeatmap for string:\n");
        _visualize $data_mode, _build_tabulated_heatmap($raw_str_src, $history_of{string_heatmap});
    }
}

# Convert a heatmapped string to a table...
my $TABLE_STR_WIDTH = 15;
sub _build_tabulated_heatmap {
    my ($str, $heatmap_ref) = @_;

    # Normalized data...
    my $max_heat = max(1, map { $_ // 0 } @{$heatmap_ref});
    my @heat = map { ($_//0) / $max_heat } @{$heatmap_ref};
    my $count_size = length($max_heat);

    # Determine colours to be used...
    my @HEAT_COLOUR = @{$lexical_config->{heatmap_col}};

    # Accumulate graph
    my @graph;
    for my $index (0..length($str)-1) {

        # Locate next char and its heat value...
        my $char = substr($str, $index, 1);
        my $abs_heat = $heatmap_ref->[$index] // 0;
        my $display_char = $char eq "\n" ? '\n'
                         : $char eq "\t" ? '\t'
                         :                 $char;

        # Graph it...
        if (@graph && length($graph[-1]{text} . $display_char) < $TABLE_STR_WIDTH && $graph[-1]{heat} == $abs_heat) {
            $graph[-1]{text} .= $display_char;
        }
        elsif ($char ne q{ } || $abs_heat != 0) {
            my $rel_heat = $heat[$index] // 0;
            push @graph, {
                    text => $display_char,
                    heat => $abs_heat,
                rel_heat => $rel_heat,
                     bar => q{*} x (($MAX_WIDTH-$TABLE_STR_WIDTH) * $rel_heat),
            };
        }
    }

    # Draw table...
    my $table;
    for my $entry (@graph) {
        my $colour_index = int( 0.5 + $#HEAT_COLOUR * $entry->{rel_heat} );
        $table .=
            q{    } .
            Term::ANSIColor::colored(
                substr($entry->{text} . q{ } x $TABLE_STR_WIDTH, 0, $TABLE_STR_WIDTH) .
                sprintf("| %-*s |%s\n", $count_size, $entry->{heat} || q{ }, $entry->{bar}),
                $HEAT_COLOUR[$colour_index]
            );
    }

    return $table;
}

# These need to be localized within regexes, so have to be package vars...
our   $subpattern_depth; # ...how many levels down in named subpatterns?

# Reset debugger variables at start of match...
sub _reset_debugger_state {
    $prev_regex_pos   = 0;     # ...start of regex
    $prev_str_pos     = 0;     # ...start of string
    $pre_is_pending   = undef; # ...no try is pending
    $interaction_mode = 's';   # ...always start in step-by-step mode
    $interaction_quit = 0;     # ...reset quit command for each regex
    $subpattern_depth = 0;     # ...start at top level of named subcalls

    $Regexp::Grammars::match_start_pos  = 0;     # ...start matching at start of string

    # Also leave a gap in the event history and JSON representations...
    _show_event $lexical_config->{display_mode}, q{};
    _show_JSON  $lexical_config->{display_mode}, q{};
}


# Set up a JSON encoder...
my ($JSON_encoder, $JSON_decoder);
BEGIN {
    ($JSON_encoder, $JSON_decoder) =
        eval{ require JSON::XS;   } ? do {
                                         my $json = JSON::XS->new->utf8(1)->pretty(1);
                                         (
                                             sub { return $json->encode(shift) },
                                             sub { return $json->decode(shift) },
                                         )
                                      }
      : eval{ require JSON;       } ? do {
                                         my $json = JSON->new->pretty(1);
                                         (
                                             sub { return $json->encode(shift) },
                                             sub { return $json->decode(shift) },
                                         )
                                      }
      : eval{ require 5.014;
              require JSON::DWIW; } ? (
                                         sub { JSON::DWIW->to_json(shift,   {pretty=>1}) },
                                         sub { JSON::DWIW->from_json(shift, {pretty=>1}) },
                                      )
      : eval{ require JSON::Syck; } ? (
                                         \&JSON::Syck::Dump,
                                         \&JSON::Syck::Load,
                                      )
      :                               (
                                        sub { '{}' },
                                        sub {  {}  },
                                      );
}

# Report some activity within the regex match...
sub _report_event {
    # Did the user quit the interactive debugger???
    return if $interaction_quit;

    # What are we matching....
    my $str_src = $_;

    # Which regex? Which event? Where in the string? Is this a recursive call?
    my ($regex_ID, $event_ID, $str_pos, %opt) = @_;
    my $nested_because  = $opt{nested_because} // q{};
    my $non_interactive = $opt{non_iteractive};

    # Locate state info for this event...
    my $state_ref = $state{$regex_ID};
    my $event_ref = $state_ref->{$event_ID};

    # Unpack the necessary info...
    my ($matchable, $is_capture, $event_type, $construct)
        = @{$event_ref}{qw< matchable is_capture event_type construct>};
    my ($construct_type, $quantifier, $regex_pos, $capture_name, $msg)
        = @{$event_ref}{qw< construct_type quantifier regex_pos capture_name msg>};
    $construct_type //= q{};

    # Reset display_mode, capture variables, and starting position on every restart...
    if ($construct_type eq '_START') {
        %capture = ();
        $Regexp::Grammars::match_start_pos = pos();
        $lexical_config = $config[$event_ref->{lexical_scope}];

        # Reset display mode only on start (i.e. not on restart)...
        if ($str_pos == 0) {
            $display_mode = $lexical_config->{display_mode};
        }
    }

    # Ignore final failure messages, except at the very end...
    if ($event_ref->{regex_failed}) {
        return if ($str_pos//0) < length($str_src);
    }

    # This variable allows us to query the start position of a submatch when at the end of the submatch...
    my $shared_str_pos_ref = $event_ref->{shared_str_pos};

    # Use the shared string pos on failure...
    if ($nested_because eq 'failed') {
        $str_pos = ${$shared_str_pos_ref // \$prev_str_pos} // $str_pos;
    }

    # Flatten aliased capture name(s)...
    if (ref $capture_name) {
        $capture_name = join ' and ', @{$capture_name}
    }

    # If we've matched, what did we match???
    my $forward_step = 0; # ... will eventually contain how far forward we stepped
    if (($matchable || $is_capture) && $event_type eq 'post' && $construct ne '|') {
        $forward_step = $str_pos - ($shared_str_pos_ref ? ${$shared_str_pos_ref} : $str_pos);
    }

    my $backtrack = q{};        # ...will store the arrow demonstrating the backtracking

    # Are we backtracking?
    my $str_backtrack_len   = min($EVENT_COL_WIDTH-1, $prev_str_pos-$str_pos);
    my $regex_backtrack_len = min($EVENT_COL_WIDTH-1, $prev_regex_pos-$regex_pos);
    my $event_str           = '<' . '~' x $str_backtrack_len;
    my $event_regex         = '<' . '~' x $regex_backtrack_len;
    if ($nested_because ne 'failed') {
        # Generate backtracking arrow...
        if ($str_pos < ($prev_str_pos//0)) {
            $backtrack = '<' . '~' x ($prev_str_pos-$str_pos-1);
        }
        elsif ($regex_pos < ($prev_regex_pos//0)) {
            $backtrack = ' ';
        }

        # Remember where we were...
        $prev_str_pos   = $str_pos;
        $prev_regex_pos = $regex_pos;
    }

    # Was there a failed pending attempt???
    my $pending_event_ID = $pre_is_pending;
    $pre_is_pending = undef;
    if (($event_type ne 'post' || $backtrack) && defined $pending_event_ID) {
        _report_event($regex_ID, $pending_event_ID, undef, nested_because=>'failed');
    }

    # Get the source code of the regex...
    my $regex_src = $state_ref->{regex_src};

    # How long is this piece of the regex???
    my $construct_len = length $construct;

    # Build msg if it's dynamic...
    if (ref($msg) eq 'CODE') {
        $msg = $msg->();
    }

    # Construct status message (if necessary)...
    $msg = $nested_because eq 'failed'        ?  q{Failed}
         : $event_type eq 'pre'  && ref $msg  ?  'Capture to ' . join ' and ', @{$msg}
         : $event_type eq 'post' && ref $msg  ?  'End of ' . join ' and ', @{$msg}
         : defined $msg                       ?  $msg
         : $construct_type eq '_START'        ?  q{Starting regex match}
         :                                       q{}
         ;

    # Report back-tracking occurred (but not when returning from named subpatterns)...
    if ($backtrack && $event_type eq 'failed_nonbacktracking') {
        $msg = q{Back-tracking past } . lc($msg) . q{ without rematching};
    }
    elsif ($backtrack && $construct_type ne '_named_subpattern_call') {
        $msg = q{Back-tracked within regex and re} . lc($msg);
    }

    # Track trying and matching...
    my $is_match    = index($msg, 'matched')   >= 0 || index($msg, 'Matched')   >= 0;
    my $is_rematch  = index($msg, 'rematched') >= 0 || index($msg, 'Rematched') >= 0;
    my $is_trying   = index($msg, 'trying')    >= 0 || index($msg, 'Trying')    >= 0;
    my $is_skip     = index($msg, 'skipping')  >= 0 || index($msg, 'Skipping')  >= 0;
    my $is_fail     = index($msg, 'failed')    >= 0 || index($msg, 'Failed')    >= 0;

    # Track string heatmap...
    if ($forward_step) {
        my @str_range = $str_pos-$forward_step+1 .. $str_pos-1;
        $_++ for @{$history_of{string_heatmap}}[@str_range];
    }
    elsif ($is_trying) {
        $history_of{string_heatmap}[$str_pos]++;
    }

    # Trace regex heatmap...
    if ($is_rematch || !$is_match && !$is_fail && !$is_skip) {
        my @regex_range = $regex_pos..$regex_pos+length($construct)-1;
        $_++ for @{$history_of{match_heatmap}}[@regex_range];
    }

    # Track start and end positions for each capture...
    if ($construct_type eq '_capture_group') {
        if ($event_type eq 'pre') {
            $capture{$capture_name}{from}      = $str_pos;
            $capture{$capture_name}{start_pos} = $regex_pos;
        }
        elsif ($event_type eq 'post') {
            $capture{$capture_name}{to} = $str_pos;
        }
    }

    # Remember when a match/fail is pending...
    my $is_pending = $matchable
                  && $event_type eq 'pre'
                  && $construct_type ne '_named_subpattern_call';
    if ($is_pending) {
        # Pre- and post- events have adjacent IDs so add 1 to get post ID...
        $pre_is_pending = $event_ID + 1;
    }

    # Send starting position to corresponding post- event...
    if ($shared_str_pos_ref && $event_type eq 'pre' && $construct ne '|') {
        ${$shared_str_pos_ref} = $str_pos;
    }

    # Compute indent for message (from paren depth + subcall depth)...
    my $indent = $INDENT x ($event_ref->{depth} + $subpattern_depth);

    # Indicate any backtracking...
    if (length($event_str) > 1 || length($event_regex) > 1) {
        $event_str   = q{} if length($event_str) == 1;
        $event_regex = q{} if length($event_regex) == 1;
        my $backtrack_msg
            = $event_str && $event_regex ? 'Back-tracking in both regex and string'
            : $event_str                 ? 'Back-tracking ' . $str_backtrack_len
                                           . ' character'
                                           . ($str_backtrack_len == 1 ? q{} : 's')
                                           . ' in string'
            :                              "Back-tracking in regex"
            ;
        $backtrack_msg = _info_colourer($backtrack_msg);
        $event_regex .= q{ } x ($EVENT_COL_WIDTH - length $event_regex);
        $event_str   .= q{ } x ($EVENT_COL_WIDTH - length $event_str);
        _show_event $display_mode,
                    sprintf("%s | %s | %s",
                             _info_colourer($event_str),
                                  _info_colourer($event_regex),
                                       $indent . $backtrack_msg);
    }

    # Colour the message...
    my $colourer = _colourer_for($msg);

    # Log (and perhaps display) event...
    _show_event $display_mode,
               sprintf("%-s | %-${EVENT_COL_WIDTH}s | %s",
                        _ws_colourer(substr($str_src . (q{ } x $EVENT_COL_WIDTH), $str_pos, $EVENT_COL_WIDTH)),
                            substr($regex_src, $regex_pos, $EVENT_COL_WIDTH),
                                $indent . $colourer->($msg));

    # Display event mode line, if appropriate...
    if ($display_mode eq 'events' && !$lexical_config->{save_to_fh}) {
        say _info_colourer( qq{\n[Events of regex at $state{$regex_ID}{location}]} );
    }

    # Generate (and perhaps display) the JSON...
    {
        # The data we're encoding...
        my $data = {
            regex_pos => $regex_pos,
            str_pos   => $str_pos,
            event     => { %{$event_ref}, msg => $msg },
        };

        # But sanitize any procedural msg...
        if (ref $data->{event}{msg} eq 'CODE') {
            delete $data->{event}{msg};
        }

        # And sanitize any reference to internal communications channel...
        my $starting_str_pos = delete $data->{event}{shared_str_pos};
        if (ref $starting_str_pos eq 'SCALAR' && ${$starting_str_pos} && ${$starting_str_pos} ne $str_pos) {
            $data->{starting_str_pos} = ${$starting_str_pos};
        }

        my $json_rep = $JSON_encoder->($data);

        # Display opening delimiter at start...
        if ($construct_type eq '_START' && $str_pos == 0) {
            _show_JSON $display_mode, '[';
        }

        # Display event data (with comma, if needed)...
        my $comma = $construct_type eq '_END' ? q{} : q{,};
        _show_JSON $display_mode, qq{    $json_rep$comma};

        # Display closing delimiter at end...
        if ($construct_type eq '_END') {
            _show_JSON $display_mode, ']';
        }

        # Display mode line...
        if ($display_mode eq 'JSON' && !$lexical_config->{save_to_fh}) {
            say _info_colourer( qq{\n[JSON data of regex at $state{$regex_ID}{location}]} );
        }
    }

    # Build and display (if appropriate) the "2D" visualizations...
    my %data = (
        regex_ID       =>  $regex_ID,
        regex_src      =>  $regex_src,
        regex_pos      =>  $regex_pos,
        construct_len  =>  $construct_len,
        str_src        =>  $str_src,
        str_pos        =>  $str_pos,
        is_match       =>  $is_match,
        is_fail        =>  $is_fail,
        is_trying      =>  $is_trying,
        is_capture     =>  $is_capture,
        backtrack      =>  $backtrack,
        forward_step   =>  $forward_step,
        nested_because =>  $nested_because,
        msg            =>  $msg,
        colourer       =>  $colourer,
        step           =>  scalar @{$history_of{visual}||[]},
    );
    _build_visualization('visual',  \%data);
    _build_visualization('heatmap', \%data);

    $data{no_window} = 1;
    _build_visualization('full_visual',  \%data);
    _build_visualization('full_heatmap', \%data);

    # Do any interaction...
    my $input;
    INPUT:
    while (!$non_interactive) {
        # Adaptive rate of display when skipping interactions...
        state $skip_rate = 0.1;
        state $MIN_SKIP_RATE = 0.001;
        $skip_rate = max($MIN_SKIP_RATE, $skip_rate * 0.98);
        _pause($skip_rate);

        # Skip interactions if current mode does not require them...
        last INPUT if $event_type ne 'break' && (
                           # Skip-to-match mode...
                           $interaction_mode eq 'm'
                        && !$is_match
                        && index($msg,'Back-tracked') < 0
                      ||
                           # Skip-to-fail mode...
                           $interaction_mode eq 'f'
                        && !$is_fail
                      ||
                           # Skip-to-end mode...
                           $interaction_mode eq 'c'
                        && $construct_type ne '_END'
                    );

        # Reset adaptive skip rate on any interaction...
        $skip_rate = 0.1;

        # Reset to step mode on a break...
        if ($event_type eq 'break') {
            $interaction_mode = 's';
        }

        # Do what, John???
        $input = _interact();

        # A <CTRL-C> terminates the process...
        if ($input eq "\cC") {
            kill 9, $$;
        }

        # An 'x' exits the process...
        elsif ($input eq 'x') {
            exit(0);
        }

        # A <CTRL-L> redraws the screen...
        elsif ($input eq "\cL") {
            _print $history_of{$display_mode}[-1]{display};
            if ($display_mode eq 'events' || $display_mode eq 'JSON') {
                say _info_colourer( qq{\n\n[\u$display_mode of regex at $state{$regex_ID}{location}]} );
            }
            next INPUT;
        }

        # Display explanation of regex...
        elsif ($input eq 'd') {
            _show_regex_description($regex_ID);
            next INPUT;
        }

        # Help!
        elsif ($input eq '?') {
            _show_help();
            next INPUT;
        }

        # Quit all debugging???
        elsif ($input eq 'q' || $input eq "\cD") {
            $interaction_quit = 1;
            last INPUT;
        }

        # Step backwards...
        elsif ($input eq '-') {
            ($input) = _revisualize($regex_ID);
            if ($input eq 'q' || $input eq "\cD") {
                $interaction_quit = 1;
                last INPUT;
            }
            next INPUT;
        }

        # Switch between visualizer/event/heatmap/JSON modes...
        elsif ($input eq 'v') {
            $display_mode = 'visual';
            _print $history_of{'visual'}[-1]{display};
            next INPUT;
        }
        elsif ($input eq 'h') {
            # Can we use heatmap mode?
            if ($heatmaps_invisible) {
                say 'Cannot show heatmaps (Term::ANSIColor unavailable)';
                say "Try 'H' instead";
                $input = '?';
            }
            # If heatmaps available, check for misuse of 'h' instead of '?'...
            else {
                my $prompt_help = $display_mode eq 'heatmap';
                $display_mode = 'heatmap';
                _print $CLEAR_SCREEN;
                _print $history_of{'heatmap'}[-1]{display};
                if ($prompt_help) {
                    say "(Type '?' for help)";
                }
            }
            next INPUT;
        }
        elsif ($input eq 'e') {
            $display_mode = 'events';
            _print $CLEAR_SCREEN;
            _print $history_of{'events'}[-1]{display};
            say _info_colourer( qq{\n\n[Events of regex at $state{$regex_ID}{location}]} );
            next INPUT;
        }
        elsif ($input eq 'j') {
            $display_mode = 'JSON';
            _print $CLEAR_SCREEN;
            _print $history_of{'JSON'}[-1]{display};
            say _info_colourer( qq{\n\n[JSON data of regex at $state{$regex_ID}{location}]} );
            next INPUT;
        }

        # Take a snapshot...
        elsif ($input eq 'V') { _save_snapshot('full_visual')             ; next INPUT; }
        elsif ($input eq 'H') { _save_snapshot('full_heatmap')            ; next INPUT; }
        elsif ($input eq 'E') { _save_snapshot('events')                  ; next INPUT; }
        elsif ($input eq 'J') { _save_snapshot('JSON')                    ; next INPUT; }
        elsif ($input eq 'D') { _show_regex_description($regex_ID,'save') ; next INPUT; }

        # Require an explicit quit request at end of match...
#        elsif ($construct_type eq '_END') {
#            print $history_of{$display_mode}[-1]{display};
#            say Term::ANSIColor::colored("(type 'q' to leave visualization)", $ERR_COL);
#            next INPUT;
#        }

        # Change of interaction mode???
        elsif ($input ~~ ['f','m','s','c']) {
            $interaction_mode = $input;
            last INPUT;
        }

        # Otherwise, move on...
        else {
            last INPUT;
        }
    }

    # At end of debugging, save data to file (if requested), and clean up...
    if ($construct_type eq '_END') {
        _save_to_fh($regex_ID, $str_src);

        %history_of = ();
        $history_of{match_heatmap} = [];
        $history_of{string_heatmap} = [];
    }

    return $input;
}

# Dump all history and config data to a stream...
sub _save_to_fh {
    my ($regex_ID, $str_src) = @_;

    # No-op if not saving to file...
    my $fh = delete $lexical_config->{save_to_fh}
        or return;

    # Extract data to correct level...
    my $match_heatmap  = delete $history_of{match_heatmap};
    my $string_heatmap = delete $history_of{string_heatmap};
    my $location       = $state{$regex_ID}{location};
    my $regex_display  = $state{$regex_ID}{regex_src};
    my $regex_original = $state{$regex_ID}{raw_regex};

    # Ensure print prints everything...
    my $prev_select = select $fh;
    local $|=1;

    # Encode and print...
    print {$fh} $JSON_encoder->({
        regex_ID       => $regex_ID,
        regex_location => $location,
        regex_original => $regex_original,
        regex_display  => $regex_display,
        string_display => $str_src,
        config         => $lexical_config,
        match_data     => $JSON_decoder->($history_of{JSON}[-1]{display}),
        match_heatmap  => $match_heatmap,
        string_heatmap => $string_heatmap,
        visualization  => \%history_of,
    }), "\n";

    # Restore filehandles...
    select $prev_select;
    $lexical_config->{save_to_fh} = $fh;
}

sub _show_regex_description {
    my ($regex_ID, $save) = @_;

    # How wide to display regex components...
    my $MAX_DISPLAY = 20;

    # The info we're displaying...
    my $info = $state{$regex_ID};

    # Coloured separator...
    my $separator = $save ? q{}
                  :         Term::ANSIColor::colored(
                                q{ } x $MAX_WIDTH . "\n",
                                $lexical_config->{desc_sep_col}
                            );

    # Direct the output...
    my $STDOUT;
    if ($save) {
        $STDOUT = _prompt_for_file('description');
    }
    else {
        my $pager  = $ENV{PAGER} // 'more';
        if ($pager eq 'less') {
            $pager .= ' -R';
        }
        open $STDOUT, '|-', $pager or return;
    }

    # Build the display...
    say {$STDOUT}
        $separator
      . join q{},
        map {
            my $indent    = $info->{$_}{indent};
            my $construct = sprintf('%-*s', $MAX_DISPLAY, $indent . $info->{$_}{construct});
            my $desc      = $indent . $info->{$_}{desc};

            # Decorate according to destination...
            if ($save) {
                $desc = '#' . $desc
            }
            else {
                $construct = Term::ANSIColor::colored($construct, $lexical_config->{desc_regex_col});
                $desc      = Term::ANSIColor::colored($desc,      $lexical_config->{desc_text_col});
            }

            # Format and return...
            if (length($indent . $info->{$_}{construct}) > 20) {
                  $construct . "\n"
                . q{ } x ($MAX_DISPLAY+2) . "$desc\n"
                . $separator
            }
            else {
                  "$construct  $desc\n"
                . $separator
            }
        }
        sort { $a <=> $b }
        grep { /^\d+$/ && exists $info->{$_}{desc} }
        keys %$info;
}

sub _show_help {
    say <<'END_HELP';
________________________________________________/ Help \______

  Motion:    s : step forwards
             - : step backwards
             m : continue to next partial match
             f : continue to next partial failure
             c : continue to end of full match
         <RET> : repeat last motion

  Display:   v : change to visualization
             e : change to event log
             h : change to heatmaps
             j : change to JSON representation
             d : describe the regex in detail

  Snapshot:  V : take snapshot of current visualization
             E : take snapshot of current event log
             H : take snapshot of current heatmaps
             J : take snapshot of current JSON representation
             D : take snapshot of regex description

  Control:   q : quit debugger and continue program
             x : exit debugger and terminate program

______________________________________________________________
END_HELP
}

# Take a snapshot of the current debugger state...
my @ERR_MODE = ( -timeout => 10, -style => $ERR_COL, -single);

sub _prompt_for_file {
    my ($data_mode) = @_;

    if (!eval { require Time::HiRes; }) {
        *Time::HiRes::time = sub { time };
    }

    # Default target for save...
    my $open_mode = '>';
    my $filename  = 'rxrx_' . $data_mode . '_' . Time::HiRes::time();

    # Request a filename...
    print "Save $data_mode snapshot as: ";
    my $input = _interact();

    # Default to paged-to-screen...
    if ($input eq "\n") {
        say '<screen>';
        $open_mode = '|-';
        $filename  = $ENV{PAGER} // 'more';
        if ($filename eq 'less') {
            $filename .= ' -R';
        }
    }

    # <TAB> selects precomputed filename...
    elsif ($input eq "\t") {
        say $filename;
        _pause(2);
    }

    # Otherwise, use whatever they type...
    else {
        $filename = $input;
        print $input;
        $filename .= readline *STDIN;
        chomp $filename;
    }

    # Set up the output stream...
    open my $fh, $open_mode, $filename or do {
        say Term::ANSIColor::colored("Can't open $filename: $!", $ERR_COL);
        say Term::ANSIColor::colored("(Hit any key to continue)", $ERR_COL);
        _interact();
        return;
    };

    return $fh;
}

sub _save_snapshot {
    my ($data_mode, $step) = @_;
    $step //= -1;

    # Open the save target...
    my $fh = _prompt_for_file($data_mode);

    # Output current state (appropriately trimmed)...
    my $state = $history_of{$data_mode}[$step]{display};
    while (substr($state, 0, 1) eq "\n") {
        substr($state, 0, 1, q{});
    }
    print {$fh} $state;

    # JSON output may be partial...
    if ($data_mode eq 'JSON' && substr($state, -2) eq ",\n") {
        print {$fh} "    { MATCH_INCOMPLETE => 1 }\n]\n";
    }

    # Clean up...
    close $fh;

    # Restore previous visuals...
    _print $history_of{$display_mode}[-1]{display};

    return;
}

sub _build_heatmap {
    my ($str, $count_ref) = @_;

    # Determine colours to be used...
    my @HEAT_COLOUR = @{$lexical_config->{heatmap_col}};

    # Normalize counts to match @HEAT_COLOUR entries...
    my $max = max 1, map { $_ // 0 } @{$count_ref};
    my @count = map { int( 0.5 + $#HEAT_COLOUR * ($_//0) / $max ) } @{$count_ref};

    # Colour each character...
    my $heatmap = q{};
    for my $n (0..length($str)-1) {
        my $heat = $HEAT_COLOUR[$count[$n] // 0];
        $heatmap .= _ws_colourer(substr($str,$n,1), $heat);
    }

    return $heatmap;
}

# Extract a window-into-string to fit it on screen...
sub _make_window {
    my %arg = @_;

    my $src       =    $arg{text}  // q{};
    my $pos       =    $arg{pos}   // 0;
    my $start_pos =    $arg{start} // 0;
    my @heatmap   = @{ $arg{heat}  // [] };
    my $ws_colour =    $arg{ws_colour};
    my $window    =   !$arg{no_window};
    my $marker    =   $arg{marker};

    # Extend heatmap and marker to length of text...
    if (@heatmap) {
        push @heatmap, (0) x (length($src) - @heatmap);
    }
    if ($marker) {
        $marker .= q{ } x (length($src) - length($marker));
    }

    # Crop to window, if necessary...
    if ($window) {

        # How big is the space we have to fill???
        my $window_width = $MAX_WIDTH - 2; # ...allow 2 chars for delimiters
        my $mid_window = $MAX_WIDTH/2;

        # Only modify values if content longer than window...
        if (length($src) > $window_width) {
            # At the start of the string, chop off the end...
            if ($pos <= $mid_window) {
                if ($marker) {
                    $marker = substr($marker, 0, $window_width);
                }
                $src = substr($src, 0, $window_width);
                substr($src,-3,3,q{...});
            }
            # At the end of the string, chop off the start...
            elsif (length($src) - $pos < $mid_window) {
                $pos       = $window_width - length($src) + $pos;
                $start_pos = $window_width - length($src) + $start_pos;
                if (@heatmap) {
                    @heatmap = @heatmap[length($src)-$window_width..$#heatmap];
                }
                if ($marker) {
                    $marker = substr($marker, length($src)-$window_width, $window_width);
                }
                $src       = substr($src, -$window_width);
                substr($src,0,3,q{...});
            }
            # In the middle of the string, centre the window on the position...
            else {
                $src        = substr($src, $pos-$mid_window+1, $window_width);
                if (@heatmap) {
                    @heatmap= splice(@heatmap, $pos-$mid_window+1, $window_width);
                }
                if ($marker) {
                    $marker = substr($marker, $pos-$mid_window+1, $window_width);
                }
                $start_pos -= $pos;
                $pos        = $window_width/2;
                $start_pos += $pos;
                substr($src,0,3,q{...});
                substr($src,-3,3,q{...});
            }
        }
    }

    # Convert to heatmap, if requested...
    if (@heatmap) {
        $src = _build_heatmap($src, \@heatmap);
    }
    elsif ($ws_colour) {
        $src = _ws_colourer($src);
    }

    # Trim trailing whitespace from marker...
    while ($marker && substr($marker,-1) eq q{ }) {
        substr($marker, -1) = q{};
    }

    return ($src, $pos, max($start_pos,0), $marker);
}

# Colour message appropriately...
sub _fail_colourer  {
    my ($str, $ws_colouring) = @_;
    my $colourer = $ws_colouring ? \&_ws_colourer : \&Term::ANSIColor::colored;
    return $colourer->($str, $lexical_config->{fail_col});
}

sub _info_colourer  {
    my ($str, $ws_colouring) = @_;
    my $colourer = $ws_colouring ? \&_ws_colourer : \&Term::ANSIColor::colored;
    return $colourer->($str, $lexical_config->{info_col});
}

sub _try_colourer {
    my ($str, $extras, $ws_colouring) = @_;
    $extras //= q{};
    my $colourer = $ws_colouring ? \&_ws_colourer : \&Term::ANSIColor::colored;
    return $colourer->($str, "$lexical_config->{try_col} $extras");
}

sub _match_colourer {
    my ($str, $extras, $ws_colouring) = @_;
    $extras //= q{};
    my $colourer = $ws_colouring ? \&_ws_colourer : \&Term::ANSIColor::colored;
    return $colourer->($str, "$lexical_config->{match_col} $extras");
}

my %DISPLAY_FOR = (
    "\n" => 'n',
    "\t" => 't',
    "\r" => 'r',
    "\f" => 'f',
    "\b" => 'b',
    "\a" => 'a',
    "\e" => 'e',
    "\0" => '0',
);

sub _ws_colourer {
    my ($str, $colour_scheme) = @_;

    # How to colour the text...
    $colour_scheme //= 'clear';
    my $ws_colour_scheme = "$colour_scheme $lexical_config->{ws_col}";

    # Accumulate the text...
    my $coloured_str = q{};
    my $prefix = q{};

    # Step through char-by-char...
    CHAR:
    for my $n (0..length($str)-1) {
        my $char = substr($str, $n, 1);

        # If it's special, handle it...
        for my $special_char (keys %DISPLAY_FOR) {
            if ($char eq $special_char) {
                if (length($prefix)) {
                    $coloured_str .= Term::ANSIColor::colored($prefix, $colour_scheme);
                    $prefix = q{};
                }
                $coloured_str .= Term::ANSIColor::colored($DISPLAY_FOR{$special_char}, $ws_colour_scheme);
                next CHAR;
            }
        }

        # Otherwise, accumulate it...
        $prefix .= $char;
    }

    # Clean up any remaining text...
    if (length($prefix)) {
        $coloured_str .= Term::ANSIColor::colored($prefix, $colour_scheme);
    }

    return $coloured_str;
}

sub _colourer_for {
    my $msg = shift;

    if (index($msg,'forgetting') >= 0 || index($msg,'Forgetting') >= 0) {
        return \&_info_colourer;
    }
    if (index($msg,'try') >= 0 || index($msg,'Try') >= 0) {
        return \&_try_colourer;
    }
    if (index($msg,'failed') >= 0 || index($msg,'Failed') >= 0) {
        return \&_fail_colourer;
    }
    if (index($msg,'matched') >= 0 || index($msg,'Matched') >= 0) {
        return \&_match_colourer;
    }
    return \&_info_colourer;
}

# Set up interaction as spiffily as possible...

if (eval{ require Term::ReadKey }) {
    *_interact = sub {
        # No interactions when piping output to a filehandle...
        return 'c' if $lexical_config->{save_to_fh};

        # Otherwise grab a single key and return it...
        Term::ReadKey::ReadMode('raw');
        my $input = Term::ReadKey::ReadKey(0);
        Term::ReadKey::ReadMode('restore');
        return $input;
    }
}
else {
    *_interact = sub {
        # No interactions when piping output to a filehandle...
        return 'c' if $lexical_config->{save_to_fh};

        # Otherwise return the first letter typed...
        my $input = readline;
        return substr($input, 0, 1);
    }
}


#====[ REPL (a.k.a. rxrx) ]=======================

# Deal with v5.16 weirdness...
BEGIN {
    if ($] >= 5.016) {
        require feature;
        feature->import('evalbytes');
        *evaluate = \&CORE::evalbytes;
    }
    else {
        *evaluate = sub{ eval shift };
    }
}

my $FROM_START = 0;

sub rxrx {
    # Handle: rxrx <filename>
    if (@_) {
        local @ARGV = @_;

        # If file is a debugger dump, decode and step through it...
        my $filetext = do { local $/; <> };
        my $dumped_data = eval { $JSON_decoder->($filetext) };
        if (ref($dumped_data) eq 'HASH' && defined $dumped_data->{regex_ID} ) {
            # Reconstruct internal state...
            my $regex_ID                = $dumped_data->{regex_ID};
            %history_of                 = %{ $dumped_data->{visualization} };
            $history_of{match_heatmap}  = $dumped_data->{match_heatmap};
            $history_of{string_heatmap} = $dumped_data->{string_heatmap};
            $display_mode               = $dumped_data->{config}{display_mode};
            $state{$regex_ID}{location} = $dumped_data->{regex_location};

            # Display...
            my $step = $FROM_START;
            my $cmd;
            while (1) {
                ($cmd, $step) = _revisualize($regex_ID, $step);
                last if $cmd =~ /[q]/i;
                $step = min($step, @{$history_of{visual}}-1);
            }
            exit;
        }

        # Otherwise, assume it's a perl source file and debug it...
        else {
            exec $^X, '-MRegexp::Debugger', @_
                or die "Couldn't invoke perl: $!";
        }
    }

    # Otherwise, be interactive...

    # Track input history...
    my $str_history   = [];
    my $regex_history = [];

    # Start with empty data...
    my $input_regex = '';
    my $regex       = '';
    my $regex_flags = '';
    my $string      = '';

    # And display it...
    _display($string, $input_regex,q{});

    INPUT:
    while (1) {
        my $input = _prompt('>');

        # String history mode?
        if ($input =~ /^['"]$/) {
            $input = _rxrx_history($str_history);
        }

        # Regex history mode?
        elsif ($input eq '/') {
            $input = _rxrx_history($regex_history);
        }

        # Are we updating the regex or string???
        if ($input =~ m{^ (?<cmd> [/"'])  (?<data> .*?) (?<endcmd> \k<cmd> (?<flags> [imsxlaud]*) )? \s*  \z }x) {

            # Compile and save the new regex...
            if ($+{cmd} eq q{/}) {
                if ($+{data} eq q{}) {
                    state $NULL_REGEX = eval q{use Regexp::Debugger; qr{(?#NULL)}; };
                    $regex = $NULL_REGEX;
                }
                else {
                    $input_regex = $+{data};
                    $regex_flags = $+{flags} // 'x';
                    $regex = evaluate qq{\n# line 0 rxrx\nuse Regexp::Debugger; qr{$+{data}}$regex_flags;};
                }

                # Report any errors...
                print "$@\n" if $@;
                print "Invalid input\n" if !defined $regex;

                # Remember it...
                push @{$regex_history}, $input;
            }

            # Otherwise compile the string (interpolated or not)...
            elsif ($+{cmd} eq q{"}) {
                $string = evaluate qq{"$+{data}"};

                # Report any errors...
                print "$@\n" if $@;
                print "Invalid input\n" if !defined $string;

                # Remember it...
                push @{$str_history}, $input;
            }
            elsif ($+{cmd} eq q{'}) {
                $string = evaluate qq{'$+{data}'};

                # Report any errors...
                print "$@\n" if $@;
                print "Invalid input\n" if !defined $string;

                # Remember it...
                push @{$str_history}, $input;
            }
        }

        # Quit if quitting requested...
        elsif ($input =~ /^ \s* [xXqQ]/x) {
            say q{};
            last INPUT;
        }

        # Help...
        elsif ($input =~ /^ \s* [?hH]/x) {
            print "\n" x 2;
            say '____________________________________________/ Help \____';
            say '                                         ';
            say '     / : Enter a pattern';
            say "     ' : Enter a new literal string";
            say '     " : Enter a new double-quoted string';
            if (eval { require IO::Prompter }) {
                say '';
                say 'CTRL-R : History completion - move backwards one input';
                say 'CTRL-N : History completion - move forwards one input';
                say '';
                say 'CTRL-B : Cursor motion - move back one character';
                say 'CTRL-F : Cursor motion - move forwards one character';
                say 'CTRL-A : Cursor motion - move to start of input';
                say 'CTRL-E : Cursor motion - move to end of input';
            }
            say '';
            say '     m : Match current string against current pattern';
            say '';
            say 'q or x : quit debugger and exit';
            next INPUT;
        }

        # Visualize the match...
        elsif ($input =~ /m/i) {
            $string =~ $regex;
        }

        # Redisplay the new regex and/or string...
        if (defined $string && defined $input_regex) {
            _display($string, $input_regex, $regex_flags);
        }
    }
}

# Lay out the regex and string as does Regexp::Debugger...
sub _display {
    my ($string, $regex, $flags) = @_;

    say "\n" x 100;
    say Term::ANSIColor::colored('regex:', 'white');
    say qq{/$regex/$flags\n\n\n};
    say Term::ANSIColor::colored('string:', 'white');
    say q{'} . _ws_colourer($string) . qq{'\n\n\n};
}


# Make whitespace characters visible (without using a regex)...
sub _quote_ws {
    my $str = shift;

    my $index;
    for my $ws_char ( ["\n"=>'\n'], ["\t"=>'\n'] ) {
        SEARCH:
        while (1) {
            $index = index($str, $ws_char->[0]);
            last SEARCH if $index < 0;
            substr($str, $index, 1, $ws_char->[1]);
        }
    }

    return $str;
}

# Hi-res sleep...
sub _pause {
    select undef, undef, undef, shift;
}

# Simple prompter...
*_prompt = eval { require IO::Prompter }
    ? sub {
            return IO::Prompter::prompt(@_)
      }
    : sub {
            my ($prompt) = @_;

            print "$prompt ";
            my $input = readline *STDIN;
            chomp $input;
            return $input;
      };


1; # Magic true value required at end of module
__END__

=head1 NAME

Regexp::Debugger - Visually debug regexes in-place


=head1 VERSION

This document describes Regexp::Debugger version 0.001016


=head1 SYNOPSIS

    use Regexp::Debugger;


=head1 DESCRIPTION

When you load this module, any regex in the same lexical scope will be visually
(and interactively) debugged as it matches.


=head1 INTERFACE

The module itself provides no API.
You load it and the debugger is automatically
activated in that lexical scope.

The debugger offers the following commands:

=over

=item C<?>

: Print a help message listing these commands

=item C<s>

: Step forwards

=item C<->

: Step backwards

=item C<m>

: Continue forward to the next event that matches something

=item C<f>

: Continue forward to the next event that fails to match something

=item C<c>

: Continue forward until the regex matches or completely backtracks

=item C<< <RETURN>/<ENTER> >>

: Repeat the previous command

=item C<v>

: Switch to visualization mode

=item C<h>

: Switch to heatmapped visualization log

=item C<e>

: Switch to the event log

=item C<j>

: Switch to the underlying JSON data

=item C<d>

: Describe each component of the regex in detail

=item C<V>

=item C<H>

=item C<H>

=item C<J>

: Take a snapshot of the corresponding display mode.

When prompted for a filename:

=over

=item C<< <RET> >>

...prints the snapshot to the terminal

=item C<< <TAB> >>

...prints the snapshot to a file named "./rxrx_I<DISPLAY_MODE>_I<TIMESTAMP>"

=item Anything else

...prints the snapshot to that file

=back

=item C<q>

: Quit the debugger and finish matching this regex without any further
  visualization. The program continues to execute and other regexes may
  still be debugged.

=item C<x>

: Exit the debugger and the entire program immediately.

=back

=head1 CONFIGURATION

You can configure the debugger by setting up a F<.rxrx> file in
in the current directory or in your home directory. This configuration
consists of I<key>:I<value> pairs
(everything else in the file is silently ignored).

=head2 Display mode configuration

If the C<C<'display'>> key is specified, the debugger starts in that
mode. The four available modes are:

    # Show dynamic visualization of matching (the default)...
    display : visual

    # Show dynamic heatmap visualization of matching...
    display : heatmap

    # Show multi-line matching event log...
    display : events

    # Show JSON encoding of matching process...
    display : JSON


=head2 Whitespace display configuration

Normally, the debugger compacts whitespaces in the regex down to a
single space character, but you can configure that with the
C<show_ws> key:

    # Compact whitespace and comments to a single space (the default)...
    show_ws : compact

    # Compact whitespace, but show comments, newlines (\n), and tabs (\t)...
    show_ws : visible

    # Don't compact whitespace, and show newlines and tabs as \n and \t...
    show_ws : original


=head2 Colour configuration

The following keys reconfigure the colours with which the debugger
displays various information:

=head3 Colours for debugging information

=over

=item *

C<try_col>

The colour in which attempts to match part of the regex are reported

=item *

C<match_col>

The colour in which successful matches of part of the regex are reported

=item *

C<fail_col>

The colour in which unsuccessful matches of part of the regex are reported

=item *

C<ws_col>

The colour in which special characters (such as "\n", "\t", "\e", etc.)
are reported (as single letters: 'n', 't', 'e', etc.)

=item *

C<info_col>

The colour in which other information is reported

=back

=head3 Colours for regex descriptions

=over

=item *

C<desc_regex_col>

The colour in which components of the regex are displayed

=item *

C<desc_text_col>

The colour in which descriptions of regex components are displayed

=item *

C<desc_sep_col>

The colour in which separators between component descriptions are displayed.

=back

=head3 Colours for heatmaps

Any key that starts with C<heatmap>... is treated as a specifier for an
equal part of the total range of each heatmap.

These names are sorted (numerically, if possible; otherwise
alphabetically) and the corresponding values are then used to display
equal percentiles from the heatmap.

For example (using numeric sorting):

    heatmap_0_colour      : cyan   on_black   #  0-33rd  percentile
    heatmap_50_colour     : yellow on_black   # 34-66th  percentile
    heatmap_100_colour    : red    on_black   # 67-100th percentile

Or, equivalently (using alphabetic sorting):

    heatmap_infrequent    : cyan   on_black   #  0-33rd  percentile
    heatmap_more_frequent : yellow on_black   # 34-66th  percentile
    heatmap_very_frequent : red    on_black   # 67-100th percentile


=head3 Colour specifications

The colour values that may be used in any of the above colour
specifications are any combination of the following (i.e. the
colour specifiers supported by the Term::ANSIColor module):

         clear           reset             bold            dark
         faint           underline         underscore      blink
         reverse         concealed

         black           red               green           yellow
         blue            magenta           cyan            white
         bright_black    bright_red        bright_green    bright_yellow
         bright_blue     bright_magenta    bright_cyan     bright_white

         on_black        on_red            on_green        on_yellow
         on_blue         on_magenta        on_cyan         on_white
         on_bright_black on_bright_red     on_bright_green on_bright_yellow
         on_bright_blue  on_bright_magenta on_bright_cyan  on_bright_white


The default colour configurations are:

    try_col    :  bold magenta  on_black
    match_col  :  bold cyan     on_black
    fail_col   :       yellow   on_red
    ws_col     :  bold blue     underline
    info_col   :       white    on_black

    desc_regex_col  :  white    on_black
    desc_text_col   :  cyan     on_black
    desc_sep_col    :  blue     on_black underline

    heatmap__20th_percentile  :  white   on_black
    heatmap__40th_percentile  :  cyan    on_blue
    heatmap__60th_percentile  :  blue    on_cyan
    heatmap__80th_percentile  :  red     on_yellow
    heatmap_100th_percentile  :  yellow  on_red


=head2 Output configuration

Normally Regexp::Debugger sends its visualizations to the terminal
and expects input from the same device.

However, you can configure the module to output its information
(in standard JSON format) to a nominated file instead, using the
C<'save_to'> option:

    save_to : filename_to_save_data_to.json

Data saved in this way may be re-animated using the C<rxrx> utility,
or by calling C<Regexp::Debugger::rxrx()> directly. (See: L<"Command-line
debugging"> for details).


=head2 Configuration API

You can also configure the debugger on a program-by-program basis, by
passing any of the above key/value pairs when the module is loaded.

For example:

    use Regexp::Debugger  fail => 'bold red',  whitespace => 'compact';

Note that any configuration specified in the user's F<.rxrx> file
is overridden by an explicit specification of this type.

The commonest use of this mechanism is to dump regex debugging
information from an non-interactive program:

    use Regexp::Debugger  save_to => 'regex_debugged.json';

Note that, when C<'save_to'> is specified within a program, the value
supplied does not have to be a string specifying the filename. You can
also provide an actual filehandle (or equivalent). For example:

    use Regexp::Debugger save_to => IO::Socket::INET->new(
                                        Proto     => "tcp",
                                        PeerAddr  => 'localhost:666',
                                    );


=head1 COMMAND-LINE DEBUGGING

The module provides a non-exported subroutine (C<rxrx()>) that
implements a useful command-line regex debugging utility.

The utility can be invoked with:

    perl -MRegexp::Debugger -E 'Regexp::Debugger::rxrx\(@ARGV\)'

which is usually aliased in the shell to C<rxrx> (and will be referred
to by that name hereafter).


=head2 Regex debugging REPL

When called without any arguments, C<rxrx> initiates a simple REPL
that allows the user to type in regexes and strings and debug matches
between them:

=over

=item *

Any line starting with a C</> is treated as a new regex to match with.
The closing C</> may be omitted. If the closing C</> is supplied, any
one or more of the following flags may be specified immediately after
it: C<x>, C<i>, C<m>, C<s>, C<a>, C<u>, C<d>, C<l>.

=item *

Any line starting with a C<'> or C<"> is treated as a new string to match
against. The corresponding closing delimiter may be omitted.

=item *

Any line beginning with C<m> causes the REPL to match the current regex
against the current string, visualizing the match in the usual way.

=item *

Any line beginning with C<q> or C<x> causes the REPL to quit and exit.

=item *

Any line beginning with C<?> invokes the help listing for the REPL.

=back

If the IO::Prompter module (version 0.004 or later) is available, the
input process remembers its history, which you can recall by typing
C<CTRL-R>. Repeated C<CTRL-R>'s step successively backwards through earlier
inputs. C<CTRL-N> steps successfully forward again.
You can then use C<CTRL-B>/C<CTRL-F>/C<CTRL-A>/C<CTRL-E> to move the
cursor around the line of recalled input, to delete or insert
characters. This is useful for modifying and retrying a recently entered
regex or string.


=head2 Debugging regexes from a dumped session

When called with a filename, C<rxrx> first checks whether the file
contains a JSON dump of a previous debugging, in which case it replays
the visualization of that regex match interactively.

This is useful for debugging non-interactive programs where the
C<'save_to'> option was used (see L<"Output configuration"> and
L<"Configuration API">).

In this mode, all the features of the interactive debugger (as listed
under L<"INTERFACE">) are fully available: you can step forwards and
backwards through the match, skip to the successful submatch or a
breakpoint, swap visualization modes, and take snapshots.


=head2 Wrap-around regex debugging

When called with the name of a file that does I<not> contain a JSON
dump, C<rxrx> attempts to execute the file as a Perl program, with
Regexp::Debugger enabled at the top level. In other words:

    rxrx prog.pl

is a convenient shorthand for:

    perl -MRegexp::Debugger prog.pl



=head1 LIMITATIONS

=head2 C</x>-mode comments

Due to limitations in the Perl C<overload::constant()> mechanism, the
current implementation cannot always distinguish whether a regex has an
external /x modifier (and hence, what whitespace and comment characters
mean). Whitespace is handled correctly in almost all cases, but
comments are not.

When processing a C<# comment to end of line> within a regex, the module
currently assumes a C</x> is in effect at start of the regex. This will cause
erroneous behaviour if an unescaped C<#> is used in a non-C</x> regex.
Note that this limitation is likely to be corrected in a future release.

This limitation does not affect the handling of comments in
C<(?x:...)> and C<(?-x:...)> blocks within the regex. These are
always correctly handled, so explicitly using one of these blocks
is a reliable workaround...as is always using the C</x> modifier
on every debugged regex.

As regards whitespace, the one case where the current implementation
does not always correctly infer behaviour is where whitespace is used to
separate a repetition qualifier from the atom it qualifies in a non-C</x>
regex, such as:

    / x + /

Because the module defaults to assuming that regexes always have C</x> applied,
this is always interpreted as:

    /\ x+\ /x

rather than what it really is, namely:

    /\ x\ +\ /

The most reliable workaround for the time being is either to always use
C</x> on any regex, or never to separate repetition qualifiers from
their preceding atoms.


=head2 Multiple 'save_to' with the same target

At present, making the same file the target of two successive C<save_to> requests
causes the second JSON data structure to overwrite the first.

This limitation will be removed in a subsequent release (but this will
certainly involve a small change to the structure of the JSON data that
is written, even when only one C<save_to> is specified).


=head2 Variable interpolations

The module handles the interpolation of strings correctly,
expanding them in-place before debugging begins.

However, it currently does not correctly handle the interpolation
of C<qr>'d regexes. That is, this:

    use Regexp::Debugger;

    my $ident = qr{ [^\W\d]\w* }x;      # a qr'd regex...

    $str =~ m{ ($ident) : (.*) }xms;    # ...interpolated into another regex

does not work correctly...and usually will not even compile.

It is expected that this limitation will be removed in a future
release, however it may only be possible to fix the problem for more
recent versions of Perl (i.e. 5.14 and later) in which the regex engine
is re-entrant.


=head1 DIAGNOSTICS

=over

=item C<< Odd number of configuration args after "use Regexp::Debugger" >>

The module expects configuration arguments (see L<"Configuration API">)
to be passed as C<< key => value >> pairs. You passed something else.


=item C<< Unknown 'show_ws' option: %s >>

The only valid options for the C<'show_ws'> configuration option are
C<'compact'>, C<'visible'>, or C<'original'>.
You specified something else (or misspelled one of the above).


=item C<< Unknown 'display' option: %s >>

The only valid options for the C<'display'> configuration option are
C<'visual'> or C<'heatmap'> or C<'events'> or C<'JSON'>.
You specified something else (or misspelled one of the above).

=item C<< Invalid 'save_to' option: %s (%s) >>

The value associated with the C<'save_to'> option is expected
to be a filehandle opened for writing, or else a string containing
the name of a file that can be opened for writing. You either passed
an unopened filehandle, an unwritable filename, or something that
wasn't a plausible file. Alternatively, if you passed a filepath,
was the directory not accessible to, or writeable by, you?

=back


=head1 DEPENDENCIES

This module only works with Perl 5.10.1 and later.

The following modules are used when available:

=over

=item Term::ANSIColor

Text colouring only works if this module can be loaded.
Otherwise, all output will be monochromatic.

=item Win32::Console::ANSI

Under Windows, text colouring also requires that this module can be loaded.
Otherwise, all output will be monochromatic.

=item File::HomeDir

If it can't find a useful value for C<$ENV{HOME}>, Regexp::Debugger
attempts to use this module to determine the user's home directory,
in order to search for a F<.rxrx> config file.

=item JSON::XS

=item JSON

=item JSON::DWIW

=item JSON::Syck

JSON output (i.e. for the C<'save_to'> option) is only
possible if one of these modules can be loaded.
Otherwise, all JSON output will default to an empty C<{}>.


=item Term::ReadKey

Single-character interactions only work if this module can be loaded.
Otherwise, all command interactions will require a C<< <RETURN> >>
after them.


=item Time::HiRes

Autogenerated timestamps (e.g. for snapshots) will only be sub-second
accurate if this module can be loaded. Otherwise, all timestamps will
only be to the nearest second.

=back


=head1 INCOMPATIBILITIES

None reported, but this module will almost certainly not play nicely
with any other that modifies regexes using C<overload::constant>.


=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-regexp-debugger@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 AUTHOR

Damian Conway  C<< <DCONWAY@CPAN.org> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2011-2012, Damian Conway C<< <DCONWAY@CPAN.org> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
