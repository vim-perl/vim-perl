# Reporting Issues

When submitting an issue relating to highlighting/folding, please attach the following:

  - A screenshot of the issue.
  - The file used in the screenshot.  If it's proprietary or too big, please try
    to reproduce the issue in a small sample file.
  - A link to your vimrc, if it exists.

These things make issues **much** easier to debug!

Also, remember that scripts under `contrib` or other third party plugins have the potential to
break your highlighting/folding; if you find an issue, please try it without any contrib scripts or
other plugins set up.

# Helping Out

If you would like to contribute to vim-perl, please be aware that we have a test suite which can
be run using the `prove` command.  We also have a regression test suite in the `build-corpus.pl`
and `verify-corpus.pl` scripts.  If you plan on making changes to vim-perl, please drop the sources
for `Moose`, `Data::Printer`, and `Regexp::Debugger` under a directory named `corpus` under the
Git root, and extract the archives.  Then run `build-corpus.pl`; this will take a few seconds.

After you've made your changes, run the test suite via `prove`, as well as the regression tests
via `verify-corpus.pl`.  The former tests a host of known situations for consistency, and the
latter simply verifies that vim-perl still highlights and folds code the way it did when you
ran `build-corpus.pl`.  Most fixes don't change highlighting, so `verify-corpus.pl` should print
nothing.  If it does, open the file(s) printed and make sure that their highlighting still makes
sense.
