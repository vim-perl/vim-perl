" Perl filetype detection for test files under xt that do not have a normal use statement.
" Maintainer:   vim-perl <vim-perl@groups.google.com>
" Installation: Put into after/ftdetect/test-files-under-xt.vim
" License: Vim License (see :help license)

function! IsPerlTestFile()
  if expand("%:e") == 't' && expand("%:p:h") =~ '/xt/'
    set filetype=perl
  endif
endfunction

au BufNewFile,BufRead *.t call IsPerlTestFile()
