" Perl highlighting for Moose keywords
" Maintainer:   vim-perl <vim-perl@groups.google.com>
" Installation: Put into after/syntax/perl/moose.vim
" License: Vim License (see :help license)

" XXX include guard
syntax match perlFunction      '\<\%(before\|after\|around\|override\|augment\)\>'
syntax keyword perlStatementProc has traits inner is super requires with subtype coerce as from via message enum class_type role_type maybe_type duck_type optimize_as type where extends isa required default does trigger lazy weak_ref auto_deref lazy_build builder documentation clearer predicate reader writer accessor init_arg initializer handles

" XXX only accept attribute "keywords" in has $attr => (...)?

" XXX catch instances where you forget the semicolon after the closing brace
"     (for before, after, and friends)?
if get(g:, 'perl_fold', 1)
  if !exists("perl_nofold_subs")
    syn region perlSubFold    start="^\<has\>[^;]*(" end=");" transparent fold keepend extend
  endif
endif
