#!/usr/bin/perl

use strict;
use warnings;
use Cwd;
use File::Find;
use File::Spec::Functions qw<catfile catdir>;
use Test::More tests => 5;
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

my $color_file = catfile('t', 'define_all.vim');
my $css_file   = catfile('t', 'vim_syntax.css');
my $hilite;

for my $lang (qw(perl perl6)) {
    my $syntax_file   = catfile('syntax', "$lang.vim");
    my $ftplugin_file = catfile('ftplugin', "$lang.vim");
    my $css_url = join('/', '..', '..', 't', 'vim_syntax.css');

    $hilite = Text::VimColor->new(
        html_full_page         => 1,
        html_inline_stylesheet => 0,
        html_stylesheet_url    => $css_url,
        vim_options            => [
            qw(-RXZ -i NONE -u NONE -U NONE -N -n), # for performance
            '+set nomodeline',          # for performance
            '+set runtimepath=.',       # don't consider system runtime files
            '+let perl_include_pod=1',
            "+source $ftplugin_file",
            "+source $syntax_file",
            "+source $color_file",      # all syntax classes should be defined
        ],
    );

    find({
        wanted   => \&test_source_file,
        no_chdir => 1,
    }, catdir('t_source', $lang));
}

sub test_source_file {
    my $file = $File::Find::name;
    return if -d $file;
    return if $file !~ /\.(?:pl|pm|pod|t)$/;

    $hilite->syntax_mark_file($file);
    my $output = $hilite->html();
    
    my $html_file = $file;
    $html_file .= '.html';
    
    SKIP: {
        # remove old failure output if present
        my $fail = "${file}_fail.html";
        unlink $fail;

        # create the corresponding html file if it's missing
        if (!-e $html_file) {
            open my $markup, '>', $html_file or die "Can't open $html_file: $!\n";
            print $markup $output;
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

