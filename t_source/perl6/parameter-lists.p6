use v6;

sub with_params ($foo) { # {{{
    ...
} # }}}

sub with_params2 ($foo is rw) { # {{{
    ...
} # }}}

sub with_params3 (Int $bar) { # {{{
    ...
} # }}}

method test_method ($self:) { # {{{
    ...
} # }}}

multi sub longname ($first;; $second) { # {{{
    ...
} # }}}

sub required_sub ($x!) { # {{{
    ...
} # }}}

sub optional_sub ($required, $optional?) { # {{{
    ...
} # }}}

sub optional_sub2 ($required, $optional = True) { # {{{
    ...
} # }}}

sub named_sub ($one, :$two, :$three) { # {{{
    ...
} # }}}

sub named_sub2 ($one, :$two($two), :$three($three)) { # {{{
    ...
} # }}}

sub slurpy ($n, *%kwargs, *@args) { # {{{
    ...
} # }}}

sub capture (|args) { # {{{
    ...
} # }}}

sub parcel_binding (\x, \y) { # {{{
    ...
} # }}}

submethod initialize ($.name, $!age) { # {{{
    ...
} # }}}
