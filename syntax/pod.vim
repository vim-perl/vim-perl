" Vim syntax file
" Language:      Perl POD format
" Maintainer:    Andy Lester <andy@petdance.com>
" Previously:    Scott Bigham <dsb@killerbunnies.org>
" Homepage:      http://github.com/petdance/vim-perl
" Bugs/requests: http://github.com/petdance/vim-perl/issues
" Last Change:   2009-08-14

" To add embedded POD documentation highlighting to your syntax file, add
" the commands:
"
"   syn include @Pod <sfile>:p:h/pod.vim
"   syn region myPOD start="^=pod" start="^=head" end="^=cut" keepend contained contains=@Pod
"
" and add myPod to the contains= list of some existing region, probably a
" comment.  The "keepend" flag is needed because "=cut" is matched as a
" pattern in its own right.


" Remove any old syntax stuff hanging around (this is suppressed
" automatically by ":syn include" if necessary).
" For version 5.x: Clear all syntax items
" For version 6.x: Quit when a syntax file was already loaded
if version < 600
  syntax clear
elseif exists("b:current_syntax")
  finish
endif

" POD commands
syn match podCommand    "^=head[1234]"  nextgroup=podCmdText contains=@NoSpell
syn match podCommand    "^=item"        nextgroup=podCmdText contains=@NoSpell
syn match podCommand    "^=over"        nextgroup=podOverIndent skipwhite contains=@NoSpell
syn match podCommand    "^=back"        contains=@NoSpell
syn match podCommand    "^=cut"         contains=@NoSpell
syn match podCommand    "^=pod"         contains=@NoSpell
syn match podCommand    "^=for"         nextgroup=podForKeywd skipwhite contains=@NoSpell
syn match podCommand    "^=begin"       nextgroup=podForKeywd skipwhite contains=@NoSpell
syn match podCommand    "^=end"         nextgroup=podForKeywd skipwhite contains=@NoSpell

" Text of a =head1, =head2 or =item command
syn match podCmdText	".*$" contained contains=podFormat,@NoSpell

" Indent amount of =over command
syn match podOverIndent	"\d\+" contained contains=@NoSpell

" Formatter identifier keyword for =for, =begin and =end commands
syn match podForKeywd	"\S\+" contained contains=@NoSpell

" An indented line, to be displayed verbatim
syn match podVerbatimLine	"^\s.*$" contains=@NoSpell

" Inline textual items handled specially by POD
syn match podSpecial	"\(\<\|&\)\I\i*\(::\I\i*\)*([^)]*)" contains=@NoSpell
syn match podSpecial	"[$@%]\I\i*\(::\I\i*\)*\>" contains=@NoSpell

" Special formatting sequences
syn region podFormat	start="[IBSCLFX]<[^<]"me=e-1 end=">" oneline contains=podFormat,@NoSpell
syn region podFormat	start="[IBSCLFX]<<\s" end="\s>>" oneline contains=podFormat,@NoSpell
syn match  podFormat	"Z<>"
syn match  podFormat	"E<\(\d\+\|\I\i*\)>" contains=podEscape,podEscape2,@NoSpell
syn match  podEscape	"\I\i*>"me=e-1 contained contains=@NoSpell
syn match  podEscape2	"\d\+>"me=e-1 contained contains=@NoSpell

" Define the default highlighting.
" For version 5.7 and earlier: only when not done already
" For version 5.8 and later: only when an item doesn't have highlighting yet
if version >= 508 || !exists("did_pod_syntax_inits")
  if version < 508
    let did_pod_syntax_inits = 1
    command -nargs=+ HiLink hi link <args>
  else
    command -nargs=+ HiLink hi def link <args>
  endif

  HiLink podCommand		Statement
  HiLink podCmdText		String
  HiLink podOverIndent		Number
  HiLink podForKeywd		Identifier
  HiLink podFormat		Identifier
  HiLink podVerbatimLine	PreProc
  HiLink podSpecial		Identifier
  HiLink podEscape		String
  HiLink podEscape2		Number

  delcommand HiLink
endif

if exists("perl_pod_spellcheck_headings")
  " Spell-check headings
  syn clear podCmdText
  syn match podCmdText    ".*$" contained contains=podFormat
endif

if exists("perl_pod_formatting")
  " By default, escapes like C<> are not checked for spelling. Remove B<>
  " and I<> from the list of escapes.
  syn clear podFormat
  syn region podFormat  start="[SCLFX]<[^<]"me=e-1 end=">" oneline contains=podFormat,@NoSpell
  syn region podFormat  start="[SCLFX]<<\s" end="\s>>" oneline contains=podFormat,@NoSpell

  " These are required so that whatever is *within* B<...> and I<...> is
  " spell-checked, but not the B or I itself.
  syn match podBoldOpen   contained "B<" contains=@NoSpell
  syn match podItalicOpen contained "I<" contains=@NoSpell

  " Same as above but for the B<< >> and I<< >> syntax.
  syn match podBoldAlternativeDelimOpen   contained "B<< " contains=@NoSpell
  syn match podItalicAlternativeDelimOpen contained "I<< " contains=@NoSpell

  " Add support for spell checking text inside B<> and I<>.
  syn region podBold start="B<[^<]"ms=s-2 end=">"me=e-1 oneline contains=podBoldItalic,podBoldOpen
  syn region podBoldAlternativeDelim start="B<<\s" end="\s>>" oneline contains=podBoldAlternativeDelimOpen

  syn region podItalic start="I<[^<]"me=e-1 end=">" oneline contains=podItalicBold,podItalicOpen
  syn region podItalicAlternativeDelim start="I<<\s" end="\s>>" oneline contains=podItalicAlternativeDelimOpen

  " Nested bold/italic and vice-versa
  syn region podBoldItalic contained start="[I]<[^<]"me=e-1 end=">" oneline
  syn region podItalicBold contained start="[B]<[^<]"me=e-1 end=">" oneline

  " Restore this (otherwise B<> is shown as bold inside verbatim)
  syn match podVerbatimLine	"^\s.*$" contains=@NoSpell

  " Specify how to display these
  hi def podBold term=bold cterm=bold gui=bold

  hi link podBoldAlternativeDelim podBold
  hi link podBoldAlternativeDelimOpen podBold
  hi link podBoldOpen podBold

  hi def podItalic term=italic cterm=italic gui=italic

  hi link podItalicAlternativeDelim podItalic
  hi link podItalicAlternativeDelimOpen podItalic
  hi link podItalicOpen podItalic

  hi def podBoldItalic term=italic,bold cterm=italic,bold gui=italic,bold
  hi def podItalicBold term=italic,bold cterm=italic,bold gui=italic,bold
endif

let b:current_syntax = "pod"

" vim: ts=8
