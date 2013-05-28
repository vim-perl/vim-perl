PREFIX?=$(HOME)/.vim

FTPLUGIN=$(PREFIX)/ftplugin
INDENT=$(PREFIX)/indent
SYNTAX=$(PREFIX)/syntax
TOOLS=$(PREFIX)/tools

default:
	@echo There is no default target.
	@echo Some targets: test, install

dirs:
	mkdir -p $(FTPLUGIN) $(INDENT) $(SYNTAX) $(TOOLS)

install: dirs
	cp ftplugin/*.vim    $(FTPLUGIN)/
	cp indent/*.vim      $(INDENT)/
	cp syntax/*.vim      $(SYNTAX)/
	cp tools/efm_perl.pl $(TOOLS)/

tarball:
	tar czvf vim-perl.tar.gz \
		ftplugin/*.vim \
		indent/*.vim \
		syntax/*.vim \
		tools/efm_perl.pl \

test:
	prove -rv t
