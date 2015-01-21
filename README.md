# vim-perl

[![Build Status](https://api.travis-ci.org/vim-perl/vim-perl.png?branch=master)](https://travis-ci.org/vim-perl/vim-perl)

This is the aggregation of all the various Perl-related syntax and
helper files for Perl 5 and Perl 6.

# Installation

You can install vim-perl using

* [Pathogen](https://github.com/tpope/vim-pathogen) and git submodules
* [Vundle](https://github.com/gmarik/vundle)
* [VAM](https://github.com/MarcWeber/vim-addon-manager)
* [vim-plug](https://github.com/junegunn/vim-plug)

They were all tested and work: please read the related documentation on the related sites.

The legacy method is to install just do a "make install" and you'll get the
.vim files all installed in your `~/.vim` directory.

## Installing using [vim-plug](https://github.com/junegunn/vim-plug)

In your `.vimrc`:

    call plug#begin('~/.vim/plugged')

    Plug 'vim-perl/vim-perl', { 'for': 'perl', 'do': 'make clean carp dancer highlight-all-pragmas moose test-more try-tiny' }

    call plug#end()

Re-source your configuration, do `PlugInstall`, and you're done.

The `do` argument is optional, and can be used 
if you want to enable any of the optional sub-syntaxes.

The `perl` argument is also optional, and only required if you want to 
lazy-load the plugin only if dealing with Perl files.

# Getting Help

Any bug reports/feature requests/patches should be directed to the [vim-perl group](https://groups.google.com/group/vim-perl).

When reporting bugs in the highlighting of items, please include an example file as well
as a screenshot demonstrating the problem.

# FAQ

## Can you add highlighting for Moose, Try::Tiny, Test::More, SQL in strings, etc?

We have syntax "extensions" under the `contrib/` directory; you can find custom highlighting
for these sorts of things there. To enable any of them, just drop the relevant
file in a `after/syntax/perl` directory visible to vim.

    $ cp contrib/dancer.vim ~/.vim/after/syntax/perl/

You can also populate the local `after/syntax/perl/` via `make`:

    $ make dancer moose

    $ ls after/syntax/perl
    dancer.vim  moose.vim

## Curly braces inside of regexes/strings are considered when I use %

(See also [GH #86](https://github.com/vim-perl/vim-perl/issues/86))

Vim itself only considers double quotes in this scenario; the matchit plugin, however,
can deal with this scenario and vim-perl's files are set up to work with it should you
choose to use it.

xoxo,<br />
eiro,<br />
Andy (andy@petdance.com)
