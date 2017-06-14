#!/usr/bin/env perl

use strict;
use warnings;
use lib 'tools';

use Local::MissingModule;
use Local::VimColor;
use Local::VimFolds;
use Local::Utils;

use File::Temp;
use JSON qw(decode_json);
use List::Util qw(min max);
use Parallel::ForkManager;
use Path::Tiny;
use Test::Differences;
use Test::More;
use Test::SharedFork;

# XXX these values are currently taken from peaksea.vim
#     what about terminal attributes like bold?
my %fg_color_map = (
    Identifier => 219,
    Statement  => 153,
    Type       => 153,
    Constant   => 110,
    Comment    => 186,
    Number     => 179,
    PreProc    => 84,
    Special    => 179,
    Todo       => 88,

    '' => 253,
);

my %bg_color_map = (
    '' => '',
);

$fg_color_map{'String'}      = $fg_color_map{'Constant'};
$fg_color_map{'Float'}       = $fg_color_map{'Number'};
$fg_color_map{'Conditional'} = $fg_color_map{'Statement'};
$fg_color_map{'Operator'}    = $fg_color_map{'Statement'};
$fg_color_map{'Keyword'}     = $fg_color_map{'Statement'};
$fg_color_map{'Function'}    = $fg_color_map{'Statement'};
$fg_color_map{'Label'}       = $fg_color_map{'Statement'};
$fg_color_map{'Repeat'}      = $fg_color_map{'Statement'};

my $GRAY =  "\e[38;5;243m";
my $RESET = "\e[0m";

sub lines_from_marked {
    my ($marked) = @_;
    my @lines = ();
    my $current_line = [];

    foreach my $elem (@$marked) {
        my ( $group, $text ) = @$elem;

        if($text =~ /\n/) {
            while(my ( $prefix, $postfix ) = $text =~ /^(.*?)\n(.*)$/s) {
                if($prefix ne '') {
                    push @$current_line, [ $group, $prefix ];
                }
                push @lines, $current_line;
                $current_line = [];
                $text = $postfix;
            }

            if($text ne '') {
                push @$current_line, [ $group, $text ];
            }
        } else {
            push @$current_line, $elem;
        }
    }
    if(@$current_line) {
        push @lines, $current_line;
    }

    return @lines;
}

# XXX not Unicode-aware! naïve implementation for now (sanity check the underlying text)
sub split_glyphs {
    my ($s) = @_;
    return $s =~ /(.)/g;
}

sub build_color_map {
    my ($marked) = @_;
    my @map;

    for my $line (lines_from_marked($marked)) {
        my $map_line = [];
        push @map, $map_line;

        for my $grouping (@$line) {
            my ( $group, $text ) = @$grouping;

            for my $glyph (split_glyphs($text)) {
                push @$map_line, $group;
            }
        }
    }

    return \@map;
}

sub build_glyph_map {
    my ($marked) = @_;
    my @map;

    for my $line (lines_from_marked($marked)) {
        my $map_line = [];
        push @map, $map_line;

        for my $grouping (@$line) {
            my ( $group, $text ) = @$grouping;

            for my $glyph (split_glyphs($text)) {
                push @$map_line, $glyph;
            }
        }
    }

    return \@map;
}

sub is_visible {
    my ($glyph) = @_;
    return $glyph !~ /\pZ/; # XXX is this good enough?
}

sub find_differently_colored_lines {
    my ($a_lines, $b_lines) = @_;
    my @differences;

    my $glyph_map  = build_glyph_map($a_lines);
    my $before_map = build_color_map($a_lines);
    my $after_map  = build_color_map($b_lines);

    # XXX assert that dimensions for maps match

    for my $lindex (0..$#$before_map) {
        my $line_no = $lindex + 1;

        my $before_line = $before_map->[$lindex];
        my $after_line  = $after_map->[$lindex];

        for my $cindex (0..$#$before_line) {
            my $column_no = $cindex + 1;

            my $glyph        = $glyph_map->[$lindex][$cindex];
            my $before_group = $before_line->[$cindex];
            my $after_group  = $after_line->[$cindex];

            my $before_fg_color = $fg_color_map{$before_group} or die "no fg color $before_group";
            my $after_fg_color  = $fg_color_map{$after_group}  or die "no fg color $after_group";
            my $before_bg_color = $bg_color_map{$before_group} || $bg_color_map{''};
            my $after_bg_color  = $bg_color_map{$after_group}  || $bg_color_map{''};

            if($before_bg_color ne $after_bg_color) {
                push @differences, [ $lindex, $cindex ];
            }
            if(is_visible($glyph) && $before_fg_color ne $after_fg_color) {
                push @differences, [ $lindex, $cindex ];
            }
        }
    }

    return \@differences;
}

sub get_color_code {
    my ($group) = @_;

    my $fg_color_code = $fg_color_map{$group};
    if($fg_color_code ne '') {
        $fg_color_code = "\e[38;5;${fg_color_code}m";
    }

    my $bg_color_code = $bg_color_map{$group} || '';
    if($bg_color_code ne '') {
        $bg_color_code = "\e[38;5;${bg_color_code}m";
    }

    return $fg_color_code . $bg_color_code;
}

sub color_line {
    my ($line) = @_;
    my @pieces;
    for my $chunk (@$line) {
        my ( $group, $text ) = @$chunk;
        my $color_code = get_color_code($group);
        push @pieces, $color_code, $text, $RESET;
    }
    return join('', @pieces);
}

sub extract_text {
    my ($line) = @_;
    return join('', map { $_->[1] } @$line);
}

# XXX only print the first N differences?
#     visually indicate the differing columns (via underline, reverse video, etc)?
#     handle terminals too narrow to show results
sub diag_differences {
    my ($before_lines, $after_lines, $diffs) = @_;
    my $num_context = 3;
    my @print_me = map { '' } 0..$#$before_lines;

    for my $diff (@$diffs) {
        my ( $line_no, undef ) = @$diff;
        for my $line (max(0, $line_no - 3)..min($#$before_lines, $line_no + 3)) {
            $print_me[$line] = 'context';
        }
    }

    for my $diff (@$diffs) {
        my ( $line_no, undef ) = @$diff;
        $print_me[$line_no] = 'diff';
    }

    my $max_line_length = 0;

    for my $lindex (0..$#print_me) {
        if($print_me[$lindex]) {
            $max_line_length = max($max_line_length, length(extract_text($before_lines->[$lindex])));
        }
    }

    for my $lindex (0..$#print_me) {
        my $line_no = $lindex + 1;
        my $padding;

        if($print_me[$lindex]) {
            $padding = ' ' x ($max_line_length - length(extract_text($before_lines->[$lindex])));
        }

        if($print_me[$lindex] eq 'context') {
            diag $GRAY, sprintf('%4d', $line_no),
                ' ',
                extract_text($before_lines->[$lindex]) . $padding,
                ' | ',
                extract_text($after_lines->[$lindex]),
                $RESET;
        } elsif($print_me[$lindex] eq 'diff') {
            diag sprintf('%4d', $line_no),
                ' ',
                color_line($before_lines->[$lindex]) . $padding,
                ' | ',
                color_line($after_lines->[$lindex]);
        }
    }
}

my $color = Local::VimColor->new(
    language => 'perl',
);

my $fold = Local::VimFolds->new(
    options => {
        perl_fold                => 1,
        perl_nofold_packages     => 1,
        perl_fold_anonymous_subs => 1,
    },
    language => 'perl',
);

my $pm         = Parallel::ForkManager->new(16);
my $iter       = get_blob_iterator('origin/p5-corpus-ng', 'corpus');

$pm->run_on_finish(sub {
    my ( undef, $status, undef, undef, undef, $data ) = @_;

    my ( $filename, $expected_marked, $got_marked, $expected_folds, $got_folds ) = @$data;

    # XXX calculate differences in child?
    my $differences = find_differently_colored_lines($expected_marked, $got_marked);
    ok(!@$differences, "colors for file '$filename' match");
    if(@$differences) {
        diag_differences([ lines_from_marked($expected_marked) ],
            [ lines_from_marked($got_marked) ], $differences);
    }
    eq_or_diff($got_folds, $expected_folds, "folds for file '$filename' match");
});

while(my ( $filename, $content ) = $iter->()) {
    next unless $filename =~ /(?:pm|pl)\z/;
    next if $pm->start;

    my $marks_filename = ($filename =~ s{\Acorpus}{corpus_marked}r) . '.json';
    my $expected_marked = decode_json(get_corpus_contents($marks_filename));
    my @expected_folds  = get_folds_for($filename);

    my $source = File::Temp->new;
    print { $source } $content;
    close $source;

    my $got_marked  = $color->markup_file($source->filename);
    my @got_folds = $fold->_get_folds($source->filename);

    $pm->finish(0, [ $filename, $expected_marked, $got_marked, \@expected_folds, \@got_folds ]);
}

$pm->wait_all_children;

unless(Test::More->builder->is_passing) {
    diag <<'END_DIAG';
The corpus test failed!  This means that among the files stored under corpus/ in the p5-corpus-ng
branch, the syntax highlighting and/or the folding has changed for one or more files.  You need
to let a vim-perl maintainer know about this!

If you are a vim-perl maintainer, please see whether or not the changes in highlighting/folding
actually make sense.  If they do, simply run build-corpus.pl to rebuild the corpus and go on your
merry way.  If they do not, you've got some fixing to do ;)
END_DIAG
}

done_testing;
