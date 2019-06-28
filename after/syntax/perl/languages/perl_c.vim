" A bunch of crap
" Maintainer:   roflcopter4
" Installation: Put into after/syntax/perl/embed.vim

if exists('b:current_syntax')
    unlet b:current_syntax
endif


" syntax region Inline_C_Code	matchgroup=inline start=+[=\\]\@<!'+ skip=+\\'+ end=+'+ contains=@cSyntax contained
" syntax region Inline_C	matchgroup=inline start=+\<awk\>+ skip=+\\$+ end=+[=\\]\@<!'+me=e-1 nextgroup=Inline_C_Code

" syntax region Inline_C_Code	matchgroup=inline start="__C__" end="__\w\+__" 	contains=@cSyntax contained
" syntax region Inline_C		matchgroup=inline start="__C__"	end="__\w\+__"me=e-1 nextgroup=Inline_C_Code containedin=perlDATA
" syntax region Inline_C_Heredoc	matchgroup=perlInline start="Inline => C" end="_END_C_" containedin=perlHereDoc,perlIndentedHereDoc contains=@cSyntax


" syn region perlHD_iC_Start	matchgroup=perlInline start=+^use Inline => C <<\z(\I\i*\)+                        end=+$+     contains=@perlTop oneline
" syn region perlHD_iC_Start	matchgroup=perlInline start=+^use Inline => C <<\s*"\z([^\\"]*\%(\\.[^\\"]*\)*\)"+ end=+$+     contains=@perlTop oneline
" syn region perlHD_iC_Start	matchgroup=perlInline start=+^use Inline => C <<\s*'\z([^\\']*\%(\\.[^\\']*\)*\)'+ end=+$+     contains=@perlTop oneline
" syn region perlHD_iC_Start	matchgroup=perlInline start=+^use Inline => C <<\s*""+                             end=+$+     contains=@perlTop oneline
" syn region perlHD_iC_Start	matchgroup=perlInline start=+^use Inline => C <<\s*''+                             end=+$+     contains=@perlTop oneline
" syn region perlHD_iC_Start	matchgroup=perlInline start="^use Inline => C << _C_CODE_"                          end=+$+     oneline

" syn region perlHD_iC	start=+^use Inline => C <<\z(\I\i*\)+                        matchgroup=perlInline end=+^\z1$+ contains=perlHD_iC_Start,@cSyntax
" syn region perlHD_iC	start=+^use Inline => C <<\s*"\z([^\\"]*\%(\\.[^\\"]*\)*\)"+ matchgroup=perlInline end=+^\z1$+ contains=perlHD_iC_Start,@cSyntax
" syn region perlHD_iC	start=+^use Inline => C <<\s*'\z([^\\']*\%(\\.[^\\']*\)*\)'+ matchgroup=perlInline end=+^\z1$+ contains=perlHD_iC_Start,@cSyntax
" syn region perlHD_iC	start=+^use Inline => C <<\s*""+                             matchgroup=perlInline end=+^$+    contains=perlHD_iC_Start,@cSyntax
" syn region perlHD_iC	start=+^use Inline => C <<\s*''+                             matchgroup=perlInline end=+^$+    contains=perlHD_iC_Start,@cSyntax
" syn region perlHD_iC	start="^use Inline => C << _C_CODE_"                        matchgroup=perlInline end=+^_C_CODE$+ contains=perlHD_iC_Start,@cSyntax
" syn region perlAutoload	matchgroup=perlInline start=+^use Inline => C <<\s*\(['c ]\=\)\z(END_\%(SUB\|OF_FUNC\|OF_AUTOLOAD\)\)\1+ end=+^\z1$+ contains=ALL

" syntax cluster InlineLanguages	add=Inline_C
" hi def link InlineLanguages	PreProc

syntax include @cSyntax syntax/c.vim
syntax region Inline_C_Data	matchgroup=perlInline start="__C__"	end="\ze__\w\+__" contains=@cSyntax containedin=perlDATA contained
syntax region Inline_C_Heredoc	matchgroup=perlInline start="\%(/\* INLINE C \*/\|// INLINE C\)$" end="\%(/\* INLINE C \*/\|// INLINE C\)$" containedin=perlHereDoc,perlIndentedHereDoc contains=@cSyntax contained
