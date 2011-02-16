" Vim syntax file
" Language:      Perl CPAN Changes file
" Maintainer:    Randy Stauner <randy@magnificent-tears.com>
" Homepage:      http://github.com/petdance/vim-perl/tree/master
" Bugs/requests: http://github.com/petdance/vim-perl/issues
" Last Change:   2011-02-10
" Spec:          http://search.cpan.org/perldoc?CPAN::Changes::Spec
"
" add a line like this to filetype.vim:
"   autocmd  BufNewFile,BufRead Changes  setf cpanchanges

if exists("b:current_syntax")
  finish
endif

" TODO: write tests into t_source/
" TODO: Error highlighting for non-matching lines?

syn match   cpanchangesRelease 		/^\S.\+/ contains=cpanchangesVersion,cpanchangesDate
syn match   cpanchangesVersion 		/^v\?[0-9._]\+/ contained
syn match   cpanchangesDate 		/\d\{4}-\d\{2}-\d\{2}/ contained
syn match   cpanchangesGroup 		/^\s\+\[.\+\]/
syn match   cpanchangesItemMarker 	/^\s\+[-*]\+/
syn match   cpanchangesDZNextRelease 	/{{$NEXT}}/

" Preamble is any text before the first line that looks like a version (or DZ marker)
" If there is no preamble then "start=/\%1l/" swallows the first release line.
" Is there a workaround other than repeating the endpattern and using "\@!" ?
syn region  cpanchangesPreamble start=/\%1l\([v0-9._]\{2,}\|{{$NEXT}}\)\@!/ end=/^\([v0-9._]\{2,}\|{{$NEXT}}\)/me=s-1

command -nargs=+ HiLink hi def link <args>

" The default highlighting.
HiLink cpanchangesVersion		Identifier
HiLink cpanchangesDate			Statement
HiLink cpanchangesGroup			Special
HiLink cpanchangesItemMarker 		SpecialChar
HiLink cpanchangesDZNextRelease 	PreProc
HiLink cpanchangesPreamble		Comment

delcommand HiLink

let b:current_syntax = "cpanchanges"
