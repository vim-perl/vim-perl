" Perl highlighting for SQL in heredocs
" Maintainer:   vim-perl <vim-perl@groups.google.com>
" Installation: Put into after/syntax/perl/heredoc-sql.vim
" License: Vim License (see :help license)

" XXX include guard

" XXX make the dialect configurable?
runtime! syntax/sql.vim
unlet b:current_syntax
syntax include @SQL syntax/sql.vim

if get(g:, 'perl_fold', 0)
  syntax region perlHereDocSQL matchgroup=perlStringStartEnd start=+<<\s*'\z(\%(END_\)\=SQL\)'+ end='^\z1$' contains=@SQL               fold extend keepend
  syntax region perlHereDocSQL matchgroup=perlStringStartEnd start='<<\s*"\z(\%(END_\)\=SQL\)"' end='^\z1$' contains=@perlInterpDQ,@SQL fold extend keepend
  syntax region perlHereDocSQL matchgroup=perlStringStartEnd start='<<\s*\z(\%(END_\)\=SQL\)'   end='^\z1$' contains=@perlInterpDQ,@SQL fold extend keepend
else
  syntax region perlHereDocSQL matchgroup=perlStringStartEnd start=+<<\s*'\z(\%(END_\)\=SQL\)'+ end='^\z1$' contains=@SQL keepend
  syntax region perlHereDocSQL matchgroup=perlStringStartEnd start='<<\s*"\z(\%(END_\)\=SQL\)"' end='^\z1$' contains=@perlInterpDQ,@SQL keepend
  syntax region perlHereDocSQL matchgroup=perlStringStartEnd start='<<\s*\z(\%(END_\)\=SQL\)'   end='^\z1$' contains=@perlInterpDQ,@SQL keepend
endif
