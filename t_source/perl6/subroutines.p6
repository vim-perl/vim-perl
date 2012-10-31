use v6;

sub foo { # {{{
    say 'hi';
} # }}}

my Int sub bar { # {{{
    return 0;
} # }}}

our Str sub name { # {{{
    return 'Jerry';
} # }}}

sub add ($a, $b) { # {{{
    return $a + $b;
} # }}}

sub add2 (Int $a, Int $b --> Int) { # {{{
    return $a + $b;
} # }}}

sub add3 (Int $a, Int $b) returns Int { # {{{
    return $a + $b;
} # }}}

my sub hello { # {{{
    say 'hello';
} # }}}

our sub goodbye { # {{{
    say 'goodbye';
} # }}}

sub GLOBAL::global { # {{{
    say "I'm in global scope!";
} # }}}

my sub &*dynamic_sub { # {{{
    ...
} # }}}

my sub dynamic_sub2 is dynamic { # {{{
    ...
} # }}}

proto sub diag($s) { # {{{
    say 'pre-dispatch';
    {*};
    say 'post-dispatch';
} # }}}

multi sub diag(Str $s) { # {{{
    say $s;
} # }}}

multi sub diag(Int $s) { # {{{
    say $s;
} # }}}

only sub diag2(Int $s) { # {{{
    say $s;
} # }}}

proto new_proto { # {{{
    ...
} # }}}

multi new_multi { # {{{
    ...
} # }}}

my multi my_multi(Int $s) { # {{{
    return $s + 1;
} # }}}

my Int multi my_multi2(Int $s) { # {{{
    return $s + 2;
} # }}}
