" Perl highlighting for Moose keywords
" Maintainer:   vim-perl <vim-perl@groups.google.com>
" Installation: Put into after/perl/moose.vim

" XXX include guard
syntax match perlFunction      '\<\%(before\|after\|around\|override\|augment\)\>'
syntax match perlStatementProc '\<\%(has\|inner\|is\|super\|requires\|with\|subtype\|coerce\|as\|from\|via\|message\|enum\|class_type\|role_type\|maybe_type\|duck_type\|optimize_as\|type\|where\|extends\)\>'

" XXX catch instances where you forget the semicolon after the closing brace
"     (for before, after, and friends)?
