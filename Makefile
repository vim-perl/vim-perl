FTPLUGIN=$(HOME)/.vim/ftplugin
INDENT=$(HOME)/.vim/indent
SYNTAX=$(HOME)/.vim/syntax

PATHOGEN_PATH=$(HOME)/.vim/bundle/vim-perl

default:
	@echo There is no default target.
	@echo Some handle targets: test, install

dirs:
	mkdir -p $(FTPLUGIN) $(INDENT) $(SYNTAX)

pathogen-install: tarball
	mkdir -p $(PATHOGEN_PATH)
	tar -C $(PATHOGEN_PATH) -zxf vim-perl.tar.gz

local:
	mkdir -p vim-perl/ftplugin vim-perl/indent vim-perl/syntax
	cp ftplugin/perl.vim   vim-perl/ftplugin
	cp ftplugin/perl6.vim  vim-perl/ftplugin
	cp ftplugin/xs.vim     vim-perl/ftplugin
	cp indent/perl.vim     vim-perl/indent
	cp indent/perl6.vim    vim-perl/indent
	cp syntax/perl.vim     vim-perl/syntax
	cp syntax/perl6.vim    vim-perl/syntax
	cp syntax/pod.vim      vim-perl/syntax
	cp syntax/tt2.vim      vim-perl/syntax
	cp syntax/tt2html.vim  vim-perl/syntax
	cp syntax/xs.vim       vim-perl/syntax


install: dirs
	cp ftplugin/perl.vim  $(FTPLUGIN)
	cp ftplugin/perl6.vim $(FTPLUGIN)
	cp ftplugin/xs.vim    $(FTPLUGIN)
	cp indent/perl.vim    $(INDENT)
	cp indent/perl6.vim   $(INDENT)
	cp syntax/perl.vim    $(SYNTAX)
	cp syntax/perl6.vim   $(SYNTAX)
	cp syntax/pod.vim     $(SYNTAX)
	cp syntax/tt2.vim     $(SYNTAX)
	cp syntax/tt2html.vim $(SYNTAX)
	cp syntax/xs.vim      $(SYNTAX)

symlinks: dirs
	ln -sf $(PWD)/ftplugin/perl.vim  $(FTPLUGIN)
	ln -sf $(PWD)/ftplugin/perl6.vim $(FTPLUGIN)
	ln -sf $(PWD)/ftplugin/xs.vim    $(FTPLUGIN)
	ln -sf $(PWD)/indent/perl.vim    $(INDENT)
	ln -sf $(PWD)/indent/perl6.vim   $(INDENT)
	ln -sf $(PWD)/syntax/perl.vim    $(SYNTAX)
	ln -sf $(PWD)/syntax/perl6.vim   $(SYNTAX)
	ln -sf $(PWD)/syntax/pod.vim     $(SYNTAX)
	ln -sf $(PWD)/syntax/tt2.vim     $(SYNTAX)
	ln -sf $(PWD)/syntax/tt2html.vim $(SYNTAX)
	ln -sf $(PWD)/syntax/xs.vim      $(SYNTAX)

tarball: 
	tar czvf vim-perl.tar.gz \
		ftplugin/perl.vim \
		ftplugin/perl6.vim \
		ftplugin/xs.vim \
		\
		indent/perl.vim \
		indent/perl6.vim \
		\
		syntax/perl.vim \
		syntax/perl6.vim \
		syntax/pod.vim \
		syntax/xs.vim \

test:
	prove -rv t
