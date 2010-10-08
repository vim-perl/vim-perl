" Language:      TT2 embedded with HTML
" Maintainer:    Andy Lester <andy@petdance.com>
" Author:        Moriki, Atsushi <4woods+vim@gmail.com>
" Homepage:      http://github.com/petdance/vim-perl
" Bugs/requests: http://github.com/petdance/vim-perl/issues
" Last Change:   2010-07-21

if exists("b:current_syntax")
    finish
endif

runtime! syntax/html.vim
unlet b:current_syntax

runtime! syntax/tt2.vim
unlet b:current_syntax

syn cluster htmlPreProc add=@tt2_top_cluster

let b:current_syntax = "tt2html"
