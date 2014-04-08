" Perl highlighting for all pragma-like modules
" Maintainer:   vim-perl <vim-perl@groups.google.com>
" Installation: Put into after/syntax/perl/highlight-all-pragmas.vim

" XXX include guard

syntax match perlStatementInclude   "\<\%(use\|no\)\s\+\l\(\i\|:\)\+"
