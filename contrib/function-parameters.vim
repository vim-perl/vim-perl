" Perl highlighting and folding for Function::Parameters keywords
" Maintainer:   vim-perl <vim-perl@groups.google.com>
" Installation: Put into after/syntax/perl/function-parameters.vim

syn match perlFunction +\<method\>\_s*+ nextgroup=perlSubName
syn match perlFunction +\<fun\>\_s*+ nextgroup=perlSubName

if get(g:, 'perl_fold', 0)
    syn region perlSubFold  start="^\z(\s*\)\<method\>.*[^};]$" end="^\z1}\s*\%(#.*\)\=$" transparent fold keepend
    syn region perlSubFold  start="^\z(\s*\)\<fun\>.*[^};]$" end="^\z1}\s*\%(#.*\)\=$" transparent fold keepend
else
    syn region perlSubFold  start="\<method\>[^;]*{" end="}" transparent fold extend
    syn region perlSubFold  start="\<fun\>[^;]*{" end="}" transparent fold extend
endif
