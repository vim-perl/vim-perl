" Perl highlighting for Test::More keywords
" Maintainer:   vim-perl <vim-perl@groups.google.com>
" Installation: Put into after/syntax/perl/test-more.vim

" XXX include guard
syntax match perlStatementProc "\<\%(plan\|use_ok\|require_ok\|ok\|is\|isnt\|diag\|like\|unlike\|cmp_ok\|is_deeply\|skip\|can_ok\|isa_ok\|pass\|fail\|BAIL_OUT\)\>"
