default:
	@echo There is no default target.

dirs:
	mkdir -p $(HOME)/.vim/ftplugin
	mkdir -p $(HOME)/.vim/indent
	mkdir -p $(HOME)/.vim/syntax

install: dirs
	cp ftplugin/perl.vim  $(HOME)/.vim/ftplugin
	cp ftplugin/perl6.vim $(HOME)/.vim/ftplugin
	cp indent/perl.vim    $(HOME)/.vim/indent
	cp indent/perl6.vim   $(HOME)/.vim/indent
	cp syntax/perl.vim    $(HOME)/.vim/syntax
	cp syntax/perl6.vim   $(HOME)/.vim/syntax
	cp syntax/pod.vim     $(HOME)/.vim/syntax

symlinks: dirs
	ln -sf $(PWD)/ftplugin/perl.vim  $(HOME)/.vim/ftplugin
	ln -sf $(PWD)/ftplugin/perl6.vim $(HOME)/.vim/ftplugin
	ln -sf $(PWD)/indent/perl.vim    $(HOME)/.vim/indent
	ln -sf $(PWD)/indent/perl6.vim   $(HOME)/.vim/indent
	ln -sf $(PWD)/syntax/perl.vim    $(HOME)/.vim/syntax
	ln -sf $(PWD)/syntax/perl6.vim   $(HOME)/.vim/syntax
	ln -sf $(PWD)/syntax/pod.vim     $(HOME)/.vim/syntax

tarball: dirs
	tar czvf vim-perl.tar.gz \
		ftplugin/*.vim \
		indent/*.vim \
		syntax/*.vim
