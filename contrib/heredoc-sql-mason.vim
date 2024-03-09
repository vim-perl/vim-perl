" Perl highlighting for SQL in heredocs
" Maintainer:   vim-perl <vim-perl@groups.google.com>
" Installation: Put into after/syntax/mason/heredoc-sql-mason.vim
" License: Vim License (see :help license)

" XXX include guard

" XXX make the dialect configurable?
runtime! syntax/sql.vim
unlet b:current_syntax
syntax include @SQL syntax/sql.vim

if get(g:, 'perl_fold', 0)
  syntax region perlHereDocSQL matchgroup=perlStringStartEnd start=+<<\s*'\z(\%(END_\)\=SQL\)'+ end='^\z1$' contained contains=@SQL               fold extend keepend
  syntax region perlHereDocSQL matchgroup=perlStringStartEnd start='<<\s*"\z(\%(END_\)\=SQL\)"' end='^\z1$' contained contains=@perlInterpDQ,@SQL fold extend keepend
  syntax region perlHereDocSQL matchgroup=perlStringStartEnd start='<<\s*\z(\%(END_\)\=SQL\)'   end='^\z1$' contained contains=@perlInterpDQ,@SQL fold extend keepend
else
  syntax region perlHereDocSQL matchgroup=perlStringStartEnd start=+<<\s*'\z(\%(END_\)\=SQL\)'+ end='^\z1$' contained contains=@SQL keepend
  syntax region perlHereDocSQL matchgroup=perlStringStartEnd start='<<\s*"\z(\%(END_\)\=SQL\)"' end='^\z1$' contained contains=@perlInterpDQ,@SQL keepend
  syntax region perlHereDocSQL matchgroup=perlStringStartEnd start='<<\s*\z(\%(END_\)\=SQL\)'   end='^\z1$' contained contains=@perlInterpDQ,@SQL keepend
endif

syn cluster perlTop add=perlHereDocSQL
