" Highlight Javascript and CSS in Mason methods
" Maintainer:   vim-perl <vim-perl@groups.google.com>
" Installation: Put into after/syntax/mason/js-css-in-mason.vim
" License: Vim License (see :help license)

" highlight Javascript inside <%method js_inline>
unlet b:current_syntax
syn include @javascript syntax/javascript.vim
syn region masonJS matchgroup=Delimiter start="<%method js_inline[^>]*>" end="</%method>" contains=@javascript,@masonTop

" ditto for css_inline
unlet b:current_syntax
syn include @css syntax/css.vim
syn region masonJS matchgroup=Delimiter start="<%method css_inline[^>]*>" end="</%method>" contains=@css,@masonTop
