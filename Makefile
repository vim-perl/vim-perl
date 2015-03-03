PREFIX?=$(HOME)/.vim

FTPLUGIN=$(PREFIX)/ftplugin
INDENT=$(PREFIX)/indent
SYNTAX=$(PREFIX)/syntax
TOOLS=$(PREFIX)/tools

default: preproc

dirs:
	mkdir -p $(FTPLUGIN) $(INDENT) $(SYNTAX) $(TOOLS)

install: dirs fix_old_vim
	cp ftplugin/*.vim    $(FTPLUGIN)/
	cp indent/*.vim      $(INDENT)/
	cp syntax/*.vim      $(SYNTAX)/
	cp tools/efm_perl.pl $(TOOLS)/

tarball:
	perl tools/make-tarball.pl

test: preproc fix_old_vim
	prove -rv t

test6: preproc
	perl t/01_highlighting.t t_source/perl6/*.t

clean:
	rm -fr after/syntax/perl

contrib_syntax:
	mkdir -p after/syntax/perl

carp: contrib_syntax
	cp contrib/carp.vim after/syntax/perl/

dancer: contrib_syntax
	cp contrib/dancer.vim after/syntax/perl/

heredoc-sql-mason: contrib_syntax
	cp contrib/heredoc-sql-mason.vim after/syntax/perl/

heredoc-sql: contrib_syntax
	cp contrib/heredoc-sql.vim after/syntax/perl/

highlight-all-pragmas: contrib_syntax
	cp contrib/highlight-all-pragmas.vim after/syntax/perl/

js-css-in-mason: contrib_syntax
	cp contrib/js-css-in-mason.vim after/syntax/perl/

method-signatures: contrib_syntax
	cp contrib/method-signatures.vim after/syntax/perl/

moose: contrib_syntax
	cp contrib/moose.vim after/syntax/perl/

test-more: contrib_syntax
	cp contrib/test-more.vim after/syntax/perl/

try-tiny: contrib_syntax
	cp contrib/try-tiny.vim after/syntax/perl/

preproc:
	tools/preproc.pl syntax/perl6.vim.pre > syntax/perl6.vim

# this gets rid of a regex optimization introduced in Vim 7.4
fix_old_vim:
	expr `vim --version|head -n1|grep -Poh '\d\.\d'|head -n1` \< 7.4 >/dev/null && sed -i 's/\\@[0-9]\+/\\@/g; /version < 704/d' syntax/perl6.vim; true
