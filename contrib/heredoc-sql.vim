" Perl highlighting for SQL in heredocs
" Maintainer:   vim-perl <vim-perl@groups.google.com>
" Installation: Put into after/syntax/perl/heredoc-sql.vim

" XXX include guard

" XXX make the dialect configurable?
runtime! syntax/sql.vim
unlet b:current_syntax
syntax include @SQL syntax/sql.vim
syntax region perlHereDocSQL matchgroup=perlStringStartEnd start=+<<\s*'\z(\%(END_\)\=SQL\)'+ end='^\z1$' contains=@SQL
syntax region perlHereDocSQL matchgroup=perlStringStartEnd start='<<\s*"\z(\%(END_\)\=SQL\)"' end='^\z1$' contains=@perlInterpDQ,@SQL
syntax region perlHereDocSQL matchgroup=perlStringStartEnd start='<<\s*\z(\%(END_\)\=SQL\)'   end='^\z1$' contains=@perlInterpDQ,@SQL
