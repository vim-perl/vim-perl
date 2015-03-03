" To use this file, you'll need the profile feature enabled (see :echo " has('profile'))
" You just need to run the following:
"
"     vim -c 'source tools/time-it.vim' [filename]
"
" And a timing report will be written to /tmp/report

" Go to the top of the file
exe "norm! 1G"

" Start profiling
syntime on

" Redraw and scroll until we've hit the bottom
redraw
while line("w$") < line("$")
    exe "norm! \<PageDown>"
    redraw
endwhile

" Clean up
syntime off
redir! > /tmp/report
silent syntime report
redir END
quit
