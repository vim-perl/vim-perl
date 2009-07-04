default:
	@echo There is no default target.

install:
	cp syntax/perl6.vim ~/.vim/syntax
	cp indent/perl6.vim ~/.vim/indent
	cp syntax/perl.vim ~/.vim/syntax
	cp indent/perl.vim ~/.vim/indent
