PREFIX?=$(HOME)/.vim

FTPLUGIN=$(PREFIX)/ftplugin
INDENT=$(PREFIX)/indent
SYNTAX=$(PREFIX)/syntax
TOOLS=$(PREFIX)/tools

default:
	@echo There is no default target.
	@echo Some handle targets: test, install

dirs:
	mkdir -p $(FTPLUGIN) $(INDENT) $(SYNTAX) $(TOOLS)

install: dirs
	cp ftplugin/*.vim    $(FTPLUGIN)
	cp indent/*.vim      $(INDENT)
	cp syntax/*.vim      $(SYNTAX)
	cp tools/efm_perl.pl $(TOOLS)

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
	ln -sf $(PWD)/syntax/tt2js.vim   $(SYNTAX)
	ln -sf $(PWD)/syntax/xs.vim      $(SYNTAX)
	ln -sf $(PWD)/tools/efm_perl.pl  $(TOOLS)

tarball:
	tar czvf vim-perl.tar.gz \
		ftplugin/*.vim \
		indent/*.vim \
		syntax/*.vim \
		tools/efm_perl.pl \

test:
	prove -rv t
