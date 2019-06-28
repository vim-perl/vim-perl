" A bunch of crap
" Maintainer:   roflcopter4
" Installation: Put into after/syntax/perl/embed.vim

if exists('b:current_syntax')
    unlet b:current_syntax
endif

syntax include @pythonSyntax syntax/python.vim
syntax region Inline_Python_Data	matchgroup=perlInline start="__Python__"	end="\ze__\w\+__"      contains=@pythonSyntax containedin=perlDATA contained
syntax region Inline_Python_Heredoc	matchgroup=perlInline start="# INLINE PYTHON$"  end="# INLINE PYTHON$" contains=@pythonSyntax containedin=perlHereDoc,perlIndentedHereDoc contained
