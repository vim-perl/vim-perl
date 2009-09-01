use strict;
use warnings;
use File::Find;
use File::Spec::Functions qw<catfile catdir>;
use Test::More 'no_plan';
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
    my $syntax_file = catfile('syntax', "$lang.vim");
    my $ftplugin_file = catfile('ftplugin', "$lang.vim");

    $hilite = Text::VimColor->new(
        html_full_page       => 1,
        html_stylesheet_file => $css_file,
        vim_options          => [
            qw(-RXZ -i NONE -u NONE -U NONE -N -n), # for performance
            '+set nomodeline',          # for performance
            '+set runtimepath=',        # don't consider system runtime files
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
        # create the corresponding html file if it's missing
        if (!-e $html_file) {
            open my $markup, '>', $html_file or die "Can't open $html_file: $!\n";
            print $markup $output;
            close $markup;
            
            skip("No output file found for '$file', creating...", 1);
        }
            
        open my $handle, '<', $html_file or die "Can't open $html_file: $!\n";
        my $expected = do { local $/; scalar <$handle> };
        
        eq_or_diff($output, $expected, "Correct output for $file");
    }
}

