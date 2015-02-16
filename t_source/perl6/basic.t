#!perl6

token foo {
    <*foo-bar>
    (<-[:]>*)
    <foo=.file>
}

token foo {
    <* < foo bar > >
}
use v6.0.0;
use Test;
say "foo bar";
@foo.push: "bar";

# Commented out since it correctly highlights "chars" in Vim 7.4,
# but the Travis-CI machines have Vim 7.3 which does it wrong.
#for 0..$string.chars-1 -> $pos {
#}

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
