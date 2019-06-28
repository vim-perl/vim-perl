" Perl highlighting for all pragma-like modules
" Maintainer:   vim-perl <vim-perl@groups.google.com>
" Installation: Put into after/syntax/perl/highlight-all-pragmas.vim
" License: Vim License (see :help license)

" XXX include guard

syntax match perlStatementInclude   "\<\%(use\|no\)\s\+\l\(\i\|:\)\+"
