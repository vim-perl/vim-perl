#!perl6

token foo {
    <*foo-bar>
    (<-[:]>*)
    <foo=.file>
}

my $foo ~~ /foobar/;
$foo /= 4;
$foo // $bar;
(1,2)[*/2];
while /foobar/ {
}
$a = $bla / 5;

$foo ~~ m«sdfdfsdf»
$foo ~~ s/foo/$bar/;

$foo ~~ m/sd$/
$foo ~~ s/sd$/foo$bar/
$foo ~~ s{sdfsdf}
$foo ~~ tr/dsf/sdf/

$<bar>
Order::Same
Bool::True
/sdfdsf/
given $foo {
    when /dsfsdf/ {
    }
}
foo::bar / 4;
while /foo/;
say @foo.grep: /dsfsdf/
say @foo.grep(/dsfsdf/)
$bla / 3;

token foo {
    <* < foo bar > >
}
use v6.0.0;
use Test;
say "foo bar";
@foo.push: "bar";

- 0o500
-0o500
-0x500
0d500

# Commented out since it correctly highlights "chars" in Vim 7.4,
# but the Travis-CI machines have Vim 7.3 which does it wrong.
for 0..$string.chars-1 -> $pos {
}

$sum += $num if $num.is-prime;

sub if'a($x) {$x}
is if'a(5), 5, "if'a is a valid sub name";

ok (my % = baz => "luhrman"), 'initialized bare sigil hash %';
if ($foo % 3 == 0) {
}

my $f = * !< 3;
isa_ok $f, Code, 'Whatever-currying !< (1)';

my $quote = q//;
my $call = q();

@data ==> grep {/<[aeiouy]>/} ==> is($(*), $(@out), 'basic test for $(*)');

sub is-cool {
}

sub q {
}

=begin foo-bar

bla

=end foo-bar

@foo».++;

$foo, $, $bar = @bla;
$foo, @, $bar = @bla;

isa_ok NaN + 1i, Complex, "NaN + 1i is a Complex number";
ok NaN + 1i ~~ NaN, "NaN + 1i ~~ NaN";
ok NaN ~~ NaN + 1i, "NaN ~~ NaN + 1i";

my $str = "bla bla &is-cool() yes";

class Foo-Bar {
    method bla { say "foo" }
}

class Bla'Bla {
    method boo { say "bar" }
}

Inf, -Inf, NaN, +Inf

# old-style octals are bad
"\10"
"\123"
# ascii nul is ok though
"\040"

# TODO: highlighting of // and grammars in general is still not good enough
#for ('/foo/bar/baz/' ~~ m/^ $<dirname>=(.* '/'+)? $<basename>=(<-[\/]>+) '/'* $ /).gist.lines {
#    %count{$0}++ if / ^ \s+ (\w+) \s+ '=>' /;   ## extract key
#};
#throws_like "my Int a = 10;", X::Syntax::Malformed, message => / sigilless /;

my()
BEGIN()

# vim: ft=perl6
