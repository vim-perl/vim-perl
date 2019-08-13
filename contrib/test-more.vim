" Perl highlighting for Test::More keywords
" Maintainer:   vim-perl <vim-perl@groups.google.com>
" Installation: Put into after/syntax/perl/test-more.vim
" License: Vim License (see :help license)

" XXX include guard
syntax match perlStatementProc "\<\%(plan\|use_ok\|require_ok\|new_ok\|ok\|is\|isnt\|diag\|explain\|note\|like\|unlike\|cmp_ok\|is_deeply\|skip\|can_ok\|isa_ok\|pass\|fail\|BAIL_OUT\|subtest\|done_testing\)\>"
