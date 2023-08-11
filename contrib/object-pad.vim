" Perl highlighting and folding for Object::Pad keywords
" Maintainer:   vim-perl <vim-perl@groups.google.com>
" Installation: Put into after/syntax/perl/object-pad.vim
" License: Vim License (see :help license)

" Class declarations
syn match perlClassDecl "\<class\s\+\%(\h\|::\)\%(\w\|::\)*" contains=perlStatementClass
syn keyword perlStatementClass  class contained
hi def link perlStatementClass  perlStatementInclude
hi def link perlClassDecl   perlType

" Class attributes
syn match perlClassAttr '\<\%(:isa\|:does\|:repl|:strict\)\>'
hi def link perlClassAttr   perlStatementInclude

" Role declarations
syn match perlRoleDecl "\<role\s\+\%(\h\|::\)\%(\w\|::\)*" contains=perlStatementRole
syn keyword perlStatementRole  role contained
hi def link perlStatementRole perlStatementInclude
hi def link perlRoleDecl   perlType

" Role attributes
syn match perlRoleAttr '\<\%(:compat\)\>'
hi def link perlRoleAttr   perlStatementInclude

" Field declarations
syn match perlFieldDecl '\<field\>\s\+[\$@%][a-zA-Z_][a-zA-Z0-9_]*' contains=perlStatementField,perlVariable
syn keyword perlStatementField field contained
hi def link perlStatementField  perlStatementStorage
hi def link perlFieldDecl   perlType

" Field attributes
syn match perlFieldAttr '\<\%(:param\|:reader\|:writer\|:mutator\|:accessor\|:weak\)\>'
hi def link perlFieldAttr   perlStatementInclude

" Method
syn match perlFunction "\<method\>\_s*" nextgroup=perlSubDeclaration

" Class constructions
syn match perlClassConstruction "\<\%(BUILD\|ADJUST\|ADJUSTPARAMS\)\>\_s*" nextgroup=perlFakeGroup
hi def link perlClassConstruction   PreProc

