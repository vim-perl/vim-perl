package Local::VimColor;

use strict;
use warnings;

use File::Spec;
use Text::VimColor;

{
    package TrueHash;
    use base 'Tie::StdHash';
    sub EXISTS { return 1 };
}
tie %Text::VimColor::SYNTAX_TYPE, 'TrueHash';

sub new {
    my ( $class, %params ) = @_;

    my $lang = $params{'language'};

    my $syntax_file   = File::Spec->catfile('syntax', "$lang.vim");
    my $ftplugin_file = File::Spec->catfile('ftplugin', "$lang.vim");
    # XXX ???
    my $css_url       = join('/', '..', '..', 't', 'vim_syntax.css');
    my $color_file    = File::Spec->catfile('t', 'define_all.vim');

    my $hilite = Text::VimColor->new(
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

    return bless {
        hilite => $hilite,
    }, $class;
}

sub color_file {
    my ( $self, $filename ) = @_;

    return $self->{'hilite'}->syntax_mark_file($filename)->html;
}

1;
