#!/usr/bin/perl

use strict;
use warnings;
use Cwd;
use File::Find;
use File::Spec::Functions qw<catfile catdir>;
use Test::More;
use Test::Differences;
use Text::VimColor 0.25;

my %LANG_HIGHLIGHTERS = (
    perl  => [
        construct_highlighter('perl', ['+let perl_include_pod=1']),
        construct_highlighter('perl', [
            '+let perl_include_pod=1',
            '+let perl_fold=1',
        ]),
        construct_highlighter('perl', [
            '+let perl_include_pod=1',
            '+let perl_fold=1',
            '+let perl_fold_anonymous_subs=1',
        ]),
    ],
    perl6 => [
        construct_highlighter('perl6', []),
    ],
);

sub construct_highlighter {
    my ( $lang, $option_set ) = @_;

    my $syntax_file   = catfile('syntax', "$lang.vim");
    my $ftplugin_file = catfile('ftplugin', "$lang.vim");
    my $css_file      = catfile('t', 'vim_syntax.css');
    my $css_url       = join('/', '..', '..', 't', 'vim_syntax.css');

    return Text::VimColor->new(
        html_full_page         => 1,
        html_inline_stylesheet => 0,
        html_stylesheet_url    => $css_url,
        all_syntax_groups      => 1,
        extra_vim_options      => [
            @$option_set,
            '+set runtimepath=.',
            "+source $ftplugin_file",
            "+source $syntax_file",
            "+syn sync fromstart",
        ],
    );
}

sub extract_custom_options {
    my ( $filename ) = @_;

    my @options;
    open my $fh, '<', $filename or return;
    while(<$fh>) {
        chomp;
        if(/^\s*#\s*extra-option:\s*(.*)/) {
            push @options, "+$1";
        }
    }
    close $fh;

    return @options;
}

sub create_custom_highlighter {
    my ( $orig, @options ) = @_;

    unshift @options, grep { /^\+let/ } $orig->vim_options;
    my ($syntax) = grep { /^\+source syntax/ } $orig->vim_options;
    my ($lang) = $syntax =~ /(\w+)\.vim/;
    return construct_highlighter($lang, \@options);
}

sub get_language_for_file {
    my ( $filename ) = @_;

    return $filename =~ /perl6/ ? 'perl6' : 'perl';
}

sub test_source_file {
    my ( $file, $highlighters ) = @_;

    foreach my $hilite (@$highlighters) {
        my @custom_options = extract_custom_options($file);
        my $output;

        if(@custom_options) {
            my $custom_hilite = create_custom_highlighter($hilite, @custom_options);
            $custom_hilite->syntax_mark_file($file);
            $output = $custom_hilite->html();
        } else {
            $hilite->syntax_mark_file($file);
            $output = $hilite->html();
        }

        my $html_file = $file;
        $html_file .= '.html';

        SKIP: {
            # remove old failure output if present
            my $fail = "${file}_fail.html";
            unlink $fail;

            # create the corresponding html file if it's missing
            if (!-e $html_file) {
                open my $markup, '>', $html_file or die "Can't open $html_file: $!\n";
                print {$markup} $output;
                close $markup;

                skip("Created $html_file", 1);
            }

            open my $handle, '<', $html_file or die "Can't open $html_file: $!\n";
            my $expected = do { local $/; scalar <$handle> };

            eq_or_diff($output, $expected, "Correct output for $file");

            # if the HTML is incorrect, write it out to a file for
            # the user to inspect
            if ($output ne $expected) {
                open my $fh, '>', $fail or die "Can't open $fail: $!\n";
                print $fh $output;
                diag("You can inspect the incorrect output at $fail");
            }
        }
    }
}

my @test_files;

if(@ARGV) {
    @test_files = @ARGV;
} else {
    find(sub {
        return if !/\.(?:pl|pm|pod|t)$/;

        push @test_files, $File::Find::name;
    }, 't_source/perl', 't_source/perl6');
}

plan tests => scalar(map { @{ $LANG_HIGHLIGHTERS{get_language_for_file($_)} } } @test_files);

foreach my $test_file (@test_files) {
    test_source_file($test_file, $LANG_HIGHLIGHTERS{ get_language_for_file($test_file) });
}
