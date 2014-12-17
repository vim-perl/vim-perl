" To use this file, you'll need the profile feature enabled (see :echo " has('profile'))
" You just need to run the following:
"
"     vim -c 'source tools/time-it.vim' [filename]
"
" And a timing report will be written to /tmp/report

syntime on
redraw
syntime off
redir! > /tmp/report
silent syntime report
redir END
quit
