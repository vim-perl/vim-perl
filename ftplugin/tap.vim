" Vim filetype plugin file
" Language:      Verbose TAP Output
" Maintainer:    vim-perl <vim-perl@googlegroups.com>
" Homepage:      http://github.com/vim-perl/vim-perl
" Bugs/requests: http://github.com/vim-perl/vim-perl/issues
" License: Vim License (see :help license)
" Last Change:   {{LAST_CHANGE}}

" Only do this when not done yet for this buffer
if exists('b:did_ftplugin')
    finish
endif
let b:did_ftplugin = 1

set foldtext=TAPTestLine_foldtext()
function! TAPTestLine_foldtext()
    let line = getline(v:foldstart)
    let sub = substitute(line, '/\*\|\*/\|{{{\d\=', '', 'g')
    return sub
endfunction

set foldminlines=5
set foldcolumn=2
set foldenable
set foldmethod=syntax
