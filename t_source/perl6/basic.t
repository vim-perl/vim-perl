#!perl6

use v6.0.0;
use Test;
say "foo bar";
@foo.push: "bar";

for 0..$string.chars-1 -> $pos {
}

$sum += $num if $num.is-prime;

my $quote = q//;
my $call = q();

sub is-cool {
}

role q {
}

=begin foo-bar

bla

=end foo-bar

@foo».++;

$foo, $, $bar = @bla;
$foo, @, $bar = @bla;


my $str = "bla bla &is-cool() yes";

class Foo-Bar {
    method bla { say "foo" }
}

class Bla'Bla {
    method boo { say "bar" }
}

# old-style octals are bad
"\10"
"\123"
# ascii nul is ok though
"\040"
