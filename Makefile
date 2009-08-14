default:
	@echo There is no default target.

dirs:
	mkdir -p ~/.vim/ftplugin
	mkdir -p ~/.vim/indent
	mkdir -p ~/.vim/syntax

install: dirs
	cp syntax/perl.vim    ~/.vim/syntax
	cp syntax/perl6.vim   ~/.vim/syntax
	cp syntax/pod.vim     ~/.vim/syntax
	cp indent/perl.vim    ~/.vim/indent
	cp indent/perl6.vim   ~/.vim/indent
	cp ftplugin/perl.vim  ~/.vim/ftplugin
	cp ftplugin/perl6.vim ~/.vim/ftplugin

symlinks: dirs
	ln -sf $(PWD)/syntax/perl.vim    ~/.vim/syntax
	ln -sf $(PWD)/syntax/perl6.vim   ~/.vim/syntax
	ln -sf $(PWD)/syntax/pod.vim     ~/.vim/syntax
	ln -sf $(PWD)/indent/perl.vim    ~/.vim/indent
	ln -sf $(PWD)/indent/perl6.vim   ~/.vim/indent
	ln -sf $(PWD)/ftplugin/perl.vim  ~/.vim/ftplugin
	ln -sf $(PWD)/ftplugin/perl6.vim ~/.vim/ftplugin

tarball: dirs
	tar czvf vim-perl.tar.gz \
		ftplugin/*.vim \
		indent/*.vim \
		syntax/*.vim
