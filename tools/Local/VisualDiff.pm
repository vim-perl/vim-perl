## no critic (RequireUseStrict)
package Local::VisualDiff;

## use critic (RequireUseStrict)
use strict;
use warnings;
use parent 'Exporter';

use Exporter qw(import);
use List::Util qw(min max);
use Test::More;

our @EXPORT_OK   = qw(find_differently_colored_lines diag_differences lines_from_marked);
our @EXPORT      = @EXPORT_OK;

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
    Error      => 253,

    '' => 253,
);

my %bg_color_map = (
    Error => 216,

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

my $GRAY       = "\e[38;5;243m";
my $MASK_COLOR = "\e[48;5;088m";
my $RESET      = "\e[0m";

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
        if($color_code) {
            push @pieces, $color_code, $text, $RESET;
        } else {
            push @pieces, $text;
        }
    }
    return join('', @pieces);
}

sub is_prefix {
    my ($maybe_prefix, $s) = @_;
    $maybe_prefix = quotemeta($maybe_prefix);
    return $s =~ /^$maybe_prefix/;
}

sub color_mask {
    my ($before, $after) = @_;

    my @before = @$before;
    my @after  = @$after;

    my @pieces;
    while(@before) {
        # the lines represented by $before and $after should
        # be the same length, and we should be processing
        # each of $before and $after in equal-sized chunks.
        # If that *doesn't* happen for some reason, @before
        # and @after could end up out of sync
        die 'this should never happen' unless @after;

        my $before_token                 = shift @before;
        my $after_token                  = shift @after;
        my ($before_group, $before_text) = @$before_token;
        my ($after_group, $after_text)   = @$after_token;

        my $text;

        if($before_text eq $after_text) {
            $text = $before_text;
        } else {
            if(is_prefix($before_text, $after_text)) {
                my $suffix = substr($after_text, length($before_text));
                unshift @after, [
                    $after_group,
                    $suffix,
                ];
                $text = $before_text;
            } elsif(is_prefix($after_text, $before_text)) {
                my $suffix = substr($before_text, length($after_text));
                unshift @before, [
                    $before_group,
                    $suffix,
                ];

                $text = $after_text;
            } else {
                die 'this should never happen';
            }
        }

        my $before_color = get_color_code($before_group);
        my $after_color  = get_color_code($after_group);

        if($before_color eq $after_color) {
            push @pieces, $GRAY . $text . $RESET;
        } else {
            push @pieces, $MASK_COLOR . $text . $RESET;
        }
    }

    # the lines represented by $before and $after should
    # be the same length, and we should be processing
    # each of $before and $after in equal-sized chunks.
    # If that *doesn't* happen for some reason, @before
    # and @after could end up out of sync
    die 'this should never happen' if @after;

    return join('', @pieces);
}

sub extract_text {
    my ($line) = @_;
    return join('', map { $_->[1] } @$line);
}

sub strip_indent {
    my ( $amount, $line ) = @_;

    my $indent = ' ' x $amount;

    my $opt_esc_seq = qr/(?:\x1b \[ \d+ (?:;\d+)* m)?/x;

    $line =~ s/^$opt_esc_seq\K$indent//;
    return $line;
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
    my $shortest_common_indent = 9999;

    for my $lindex (0..$#print_me) {
        if($print_me[$lindex]) {
            my $line = extract_text($before_lines->[$lindex]);
            $max_line_length = max($max_line_length, length($line));
            my ( $indent ) = $line =~ /^(\s*)/;
            $shortest_common_indent = min($shortest_common_indent, length($indent));
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
                strip_indent($shortest_common_indent, extract_text($before_lines->[$lindex]) . $padding),
                ' | ',
                strip_indent($shortest_common_indent, extract_text($after_lines->[$lindex])  . $padding),
                ' | ',
                $RESET;
        } elsif($print_me[$lindex] eq 'diff') {
            diag sprintf('%4d', $line_no),
                ' ',
                strip_indent($shortest_common_indent, color_line($before_lines->[$lindex]) . $padding),
                ' | ',
                strip_indent($shortest_common_indent, color_line($after_lines->[$lindex])  . $padding),
                ' | ',
                strip_indent($shortest_common_indent, color_mask($before_lines->[$lindex], $after_lines->[$lindex]));
        }
    }
}

1;
