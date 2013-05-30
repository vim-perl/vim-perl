" Perl highlighting for SQL in heredocs
" Maintainer:   vim-perl <vim-perl@groups.google.com>
" Installation: Put into after/syntax/perl/heredoc-sql.vim

" XXX include guard

" XXX make the dialect configurable?
runtime! syntax/sql.vim
unlet b:current_syntax
syntax include @SQL syntax/sql.vim
" XXX highlight $table in "END_SQL"?
syntax region perlHereDocSQL matchgroup=perlStringStartEnd start='<<\s*\(['"]\=\)\z(\%(END_\)\=SQL\)\1' end='^\z1$' contains=@SQL
