package Local::VimColor;

use strict;
use warnings;

use File::Spec;
use Text::VimColor;

sub new {
    my ( $class, %params ) = @_;

    my $lang = $params{'language'};

    my $syntax_file   = File::Spec->catfile('syntax', "$lang.vim");
    my $ftplugin_file = File::Spec->catfile('ftplugin', "$lang.vim");
    # XXX ???
    my $css_url       = join('/', '..', '..', 't', 'vim_syntax.css');

    my $hilite = Text::VimColor->new(
        html_full_page         => 1,
        html_inline_stylesheet => 0,
        html_stylesheet_url    => $css_url,
        extra_vim_options            => [
            '+set runtimepath=.',       # don't consider system runtime files
            '+let perl_include_pod=1',
            "+source $ftplugin_file",
            "+source $syntax_file",
            '+syn sync fromstart',
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

sub markup_file {
    my ( $self, $filename ) = @_;

    return $self->{'hilite'}->syntax_mark_file($filename)->marked;
}

1;
