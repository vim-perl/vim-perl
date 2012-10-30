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

my sub hello { # {{{
    say 'hello';
} # }}}

our sub goodbye { # {{{
    say 'goodbye';
} # }}}

sub prototype;

sub GLOBAL::global { # {{{
    say "I'm in global scope!";
} # }}}

my sub &*dynamic_sub { # {{{
    ...
} # }}}

my sub dynamic_sub2 is dynamic { # {{{
    ...
} # }}}

# multi
# proto
# only 
