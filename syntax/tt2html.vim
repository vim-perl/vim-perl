" Vim syntax file
" Language: TT2 ( Inner HTML )
" Last Change:  21 Jul 2010
" Maintainar:   MORIKI Atsushi <4woods+vim@gmail.com>
"

if exists("b:current_syntax")
  finish
endif

runtime! syntax/html.vim
unlet b:current_syntax

runtime! syntax/tt2.vim
unlet b:current_syntax

syn cluster htmlPreProc add=@tt2_top_cluster

let b:current_syntax = "tt2html"
