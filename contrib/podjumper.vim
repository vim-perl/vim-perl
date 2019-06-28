" License: Vim License (see :help license)

" PerlPodJumper() will:
" 1) Find the closests attribute (has) or sub definition and jump to
"    the first =head2 section with the same name.
" 2) Find the closests =head2 and jump to the first sub or attribute
"    definition with the same name.
"
" Example mapping to enable this functionality:
" let g:perl_podjumper_key=',p'

let s:perl_podjumper_lastpos = ['', 0, 0]

function! PerlPodJumper()
    let s:currline = line('.')
    let s:currcol = col('.')
    normal $

    call cursor(s:currline + 1, 0)
    let [s:subline, s:subcol] = searchpos('^\s*\(has\|sub\)\s\+\zs\(\w\+\)', 'bcW')
    let s:subname = expand('<cword>')
    let s:sublen = s:currline - s:subline

    call cursor(s:currline + 1, 0)
    let [s:podline, s:podcol] = searchpos('=head2\s\zs\(\w\+\)\>', 'bcW')
    let s:podname = expand('<cword>')
    let s:podlen = s:currline - s:podline

    call cursor(s:currline, s:currcol)

    if (s:subline != 0 && 0 <= s:sublen && (s:podlen < 0 || s:sublen < s:podlen))
      if (s:subname == s:perl_podjumper_lastpos[0])
        call cursor(s:perl_podjumper_lastpos[1], s:perl_podjumper_lastpos[2])
      else
        let [s:gotoline, s:gotocol] = searchpos('^=head2\s' . s:subname . '\>', 'w')
        call cursor(s:gotoline ? s:gotoline : s:currline, s:currcol)
      endif
      let s:perl_podjumper_lastpos = [s:subname, s:currline, s:currcol]
    endif

    if (s:podline != 0 && 0 <= s:podlen && (s:sublen < 0 || s:podlen < s:sublen))
      if (s:podname == s:perl_podjumper_lastpos[0])
        call cursor(s:perl_podjumper_lastpos[1], s:perl_podjumper_lastpos[2])
      else
        let [s:gotoline, s:gotocol] = searchpos('^\s*\(has\|sub\)\s\+' . s:podname, 'w')
        call cursor(s:gotoline ? s:gotoline : s:currline, s:currcol)
      endif
      let s:perl_podjumper_lastpos = [s:podname, s:currline, s:currcol]
    endif
endfunction

if (exists("g:perl_podjumper_key"))
  :execute "map " . g:perl_podjumper_key . " :call PerlPodJumper()<CR>"
endif
