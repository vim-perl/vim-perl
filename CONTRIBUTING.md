# Reporting Issues

When submitting an issue relating to highlighting, please attach the following:

  - A screenshot of the issue.
  - The file used in the screenshot.  If it's proprietary or too big, please try
    to reproduce the issue in a small sample file.
  - A link to your vimrc, if it exists.

These things make issues **much** easier to debug!

Also, remember that scripts under `contrib` or other third party plugins have the potential to
break your highlighting; if you find an issue, please try it without any contrib scripts or
other plugins set up.

# Helping Out

If you would like to contribute to vim-perl (which would be greatly appreciated!), you may find
the `build-corpus.pl` and `verify-corpus.pl` scripts of use.  What I do is drop the sources
for `Moose`, `Data::Printer`, and `Regexp::Debugger` in the corpus directory and use the scripts
to make sure my changes don't cause regressions in highlighting and folding.
