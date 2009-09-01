" Vim color file
" Filename: define_all
" Maintainer: Hinrik Örn Sigurðsson <hinrik.sig at gmail dot com>
" Installation: Drop this file in your $VIMRUNTIME/colors/ directory
" 
" This is a dummy color file that defines a color for every syntax class.

if version > 580
    " no guarantees for version 5.8 and below,
    " but this makes it stop complaining
    hi clear
    if exists("syntax_on")
        syntax reset
    endif
endif

let g:colors_name = "define_all"

hi Normal           ctermfg=7
hi Comment          ctermfg=7
hi Constant         ctermfg=7
hi Special          ctermfg=7
hi Identifier       ctermfg=7
hi Statement        ctermfg=7
hi PreProc          ctermfg=7
hi Type             ctermfg=7
hi Underlined       ctermfg=7
hi Ignore           ctermfg=7
hi Error            ctermfg=7
hi Todo             ctermfg=7
hi String           ctermfg=7
hi Character        ctermfg=7
hi Number           ctermfg=7
hi Boolean          ctermfg=7
hi Float            ctermfg=7
hi Function         ctermfg=7
hi Conditional      ctermfg=7
hi Repeat           ctermfg=7
hi Label            ctermfg=7
hi Operator         ctermfg=7
hi Keyword          ctermfg=7
hi Exception        ctermfg=7
hi Include          ctermfg=7
hi Define           ctermfg=7
hi Macro            ctermfg=7
hi PreCondit        ctermfg=7
hi StorageClass     ctermfg=7
hi Typedef          ctermfg=7
hi Tag              ctermfg=7
hi SpecialChar      ctermfg=7
hi Delimiter        ctermfg=7
hi SpecialComment   ctermfg=7
hi Debug            ctermfg=7
