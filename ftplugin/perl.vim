" Vim filetype plugin file
" Language:      Perl
" Maintainer:    Andy Lester <andy@petdance.com>
" Homepage:      http://github.com/petdance/vim-perl
" Bugs/requests: http://github.com/petdance/vim-perl/issues
" Last Change:   2009-08-14

if exists("b:did_ftplugin") | finish | endif
let b:did_ftplugin = 1

" Make sure the continuation lines below do not cause problems in
" compatibility mode.
let s:save_cpo = &cpo
set cpo-=C

setlocal formatoptions+=crq
setlocal keywordprg=perldoc\ -f

setlocal comments=:#
setlocal commentstring=#%s

" Change the browse dialog on Win32 to show mainly Perl-related files
if has("gui_win32")
    let b:browsefilter = "Perl Source Files (*.pl)\t*.pl\n" .
		       \ "Perl Modules (*.pm)\t*.pm\n" .
		       \ "Perl Documentation Files (*.pod)\t*.pod\n" .
		       \ "All Files (*.*)\t*.*\n"
endif

" Provided by Ned Konz <ned at bike-nomad dot com>
"---------------------------------------------
setlocal include=\\<\\(use\\\|require\\)\\>
setlocal includeexpr=substitute(substitute(v:fname,'::','/','g'),'$','.pm','')
setlocal define=[^A-Za-z_]

" The following line changes a global variable but is necessary to make
" gf and similar commands work.  The change to iskeyword was incorrect.
" Thanks to Andrew Pimlott for pointing out the problem. If this causes a
" problem for you, add an after/ftplugin/perl.vim file that contains
"       set isfname-=:
set isfname+=:

" Set this once, globally.
if !exists("perlpath")
    if executable("perl")
      try
	if &shellxquote != '"'
	    let perlpath = system('perl -e "print join(q/,/,@INC)"')
	else
	    let perlpath = system("perl -e 'print join(q/,/,@INC)'")
	endif
	let perlpath = substitute(perlpath,',.$',',,','')
      catch /E145:/
	let perlpath = ".,,"
      endtry
    else
	" If we can't call perl to get its path, just default to using the
	" current directory and the directory of the current file.
	let perlpath = ".,,"
    endif
endif

" Append perlpath to the existing path value, if it is set.  Since we don't
" use += to do it because of the commas in perlpath, we have to handle the
" global / local settings, too.
if &l:path == ""
    if &g:path == ""
        let &l:path=perlpath
    else
        let &l:path=&g:path.",".perlpath
    endif
else
    let &l:path=&l:path.",".perlpath
endif
"---------------------------------------------

" Undo the stuff we changed.
let b:undo_ftplugin = "setlocal fo< com< cms< inc< inex< def< isf< kp< path<" .
	    \	      " | unlet! b:browsefilter"

" Restore the saved compatibility options.
let &cpo = s:save_cpo
