" Perl highlighting for Try::Tiny keywords
" Maintainer:   vim-perl <vim-perl@groups.google.com>
" Installation: Put into after/syntax/perl/try-tiny.vim
" License: Vim License (see :help license)

" XXX include guard
syntax match perlStatementProc "\<\%(try\|catch\|finally\)\>"

" XXX catch instances where you forget the semicolon after the closing brace?
