#!/usr/bin/perl

use strict;
use warnings;
use lib 'tools';

use Local::VisualDiff;

use Cwd;
use File::Find;
use File::Spec::Functions qw<catfile catdir>;
use JSON qw(decode_json encode_json);
use Test::More;
use Test::Differences;
use Text::VimColor 0.25;

my %HIGHLIGHTERS = (
    'With pod' =>
        construct_highlighter('perl', ['+let perl_include_pod=1']),
    'With pod and fold' =>
        construct_highlighter('perl', [
            '+let perl_include_pod=1',
            '+let perl_fold=1',
        ]),
    'With pod and fold and anonymous subs' =>
        construct_highlighter('perl', [
            '+let perl_include_pod=1',
            '+let perl_fold=1',
            '+let perl_fold_anonymous_subs=1',
        ]),
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

sub test_source_file {
    my ( $file, $highlighters ) = @_;

    while ( my ( $desc, $hilite ) = each %{$highlighters} ) {
        my @custom_options = extract_custom_options($file);
        my $output;

        if(@custom_options) {
            my $custom_hilite = create_custom_highlighter($hilite, @custom_options);
            $custom_hilite->syntax_mark_file($file);
            $output = $custom_hilite->marked;
        } else {
            $hilite->syntax_mark_file($file);
            $output = $hilite->marked;
        }

        my $marked_file = $file;
        $marked_file .= '.json';

        SKIP: {
            # create the corresponding html file if it's missing
            if (!-e $marked_file) {
                open my $markup, '>', $marked_file or die "Can't open $marked_file: $!\n";
                print {$markup} encode_json($output);
                close $markup;

                skip("Created $marked_file", 1);
            }

            open my $handle, '<', $marked_file or die "Can't open $marked_file: $!\n";
            my $expected = decode_json(do { local $/; scalar <$handle> });

            my $differences = find_differently_colored_lines($expected, $output);
            ok(!@$differences, "Correct output for $file: $desc");

            # if the markup is incorrect, write it out to a file for
            # the user to inspect
            if (@$differences) {
                diag_differences([ lines_from_marked($expected) ],
                    [ lines_from_marked($output) ], $differences);
                diag("if the middle column is correct, you can delete $marked_file and re-run this test to regenerate the file based on the current syntax definitions");
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
    }, 't_source/perl');
}

plan tests => @test_files * scalar keys %HIGHLIGHTERS;

foreach my $test_file (@test_files) {
    test_source_file($test_file, \%HIGHLIGHTERS);
}
