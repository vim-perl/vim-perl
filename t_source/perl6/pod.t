=foobar
sdfsdfsdf

    =for code
    sdfsdfsdf

    =foobar
    sdfsdfsdf

    =for foo
    sdfsdfsdfsdf

    =begin code
    foo() + $bar

    =end code

    # TODO: 'foobar' would be incorrectly highlighted as code because
    # the highlighting of implicit code doesn't care about the indent
    # level of the Pod block
    #=begin pod
    #foobar
    #=end pod
    #=pod
    #foobar

=begin bla
foo
    bar
=end bla

=begin pod
foo
    bar
=end pod

=begin foo :nested(3)
and so,  all  of  the  villages chased
Albi,   The   Racist  Dragon, into the
very   cold   and  very  scary    cave

and it was so cold and so scary in
there,  that  Albi  began  to  cry

    =for bar
    Dragon Tears!

Which, as we all know...

    =for bar
    Turn into Jelly Beans!
=end foo

=begin bla

=code
3+3
foo

foo

=end bla

    =code
    sdfgdfgdfg

bar

# vim: ft=perl6
