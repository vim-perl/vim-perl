#!perl6

for @foo <-> $value {
}
sub infix:<->(Foo) is required {
}

my &double-invert = &invert o &double;
my &double-invert = &invert ∘ &double;

"foo $bar.baz() $?CLASS.hi() $gsdf.hlagh(foo => 3) $much.^meta().wow()"

( < foo bar>)
class Request { }

ok("a cat_O_9_tails" ~~ m:s/<alpha> <ident>/, 'Standard captures' );

is 'aa'.trans(/ <after a> ./ => 'b'), 'ab', 'trans with look-around regex';
is ("!$_!" for (1, 2)>>.trans((1..26) => (14..26,1..13))), <!14! !15!>, "same with explicit for";
is $s.trans([<X Y>] => [{++$x},{++$y}]), 'a3b3c4d4', 'can use closures in pairs of arrays';

token twigil:sym<=> { <sym> }
%*LANG<Q>       = ::STD::Q ;
[@(@foo)]
[@bar]
when :(Str $ where /^The \s \S+ \s \w+$/) { }

$foo.state
$foo.die
@p = $x [[+]]= 6, 7;

@foo Z @bar
is (1 R[R[R-]] 2), 1, 'R[R[R-]] works';

my @seq = map { $_ ~ ++$ }, <a b c>;
$c++ for $@a;

ok "a" ![!eq] "a", '![!eq] is legal and works (1)';
is A.new.m, 'aaa',  '[~] works in first class';
my $l = (1,2,3 Z, 4,5,6 Z, 7,8,9);

nok $mh (<+) $m, "Our MixHash is not a msubset of our Mix (texas)";
ok $b (<) $bub, "(<) - {$b.gist} is a strict submix of {$bub.gist} (texas)";

is test_ff({/B/ fff^ /B/ }, <A B A B A>), 'xBAxx', '/B/ fff^ /B/, lhs == rhs';

use v6.*
use v6*

rule => "foo"
-100
is Inf / 100, Inf;
is Inf*-100, -Inf;
is Inf / -100, -Inf;
is 100 / Inf, 0;

@definitions = [.[0].words[0], .[1].contents[0]];

[['foo']];

X::Foo::Bar
bag()
Str()

is showkv([(.)] @d), showkv(∅), "Bag multiply reduce works on nothing";

.>>[0]>>.Str.unique;

sub process-pod-dir($dir, :&sorted-by = &[cmp], :$sparse) { }

use Foo::Xbar; # not a cross-operator

Zfoobar.new;
Rcmp

S|

proto sub infix:«>»(Any, Any) returns Bool:D is assoc<chain>
multi sub infix:«>»(Int:D, Int:D)
multi sub infix:«>»(Num:D, Num:D)
multi sub infix:«>»(Real:D, Real:D)

proto sub infix:<<lt>>(Mu, Mu) returns Bool:D is assoc<chain>
multi sub infix:<lt>(Mu,    Mu)
multi sub infix:<lt>(Str:D, Str:D)

v5.2.*
v1.2+
v1.2.0.0.0.0.0
v1

[1,2] xx 3;

token foo {
    <*foo-bar>
    (<-[:]>*)
    <foo=.file>
}

"foo = $<foo>";

state %sub-menus = @menu>>.key>>[0] Z=> @menu>>.value;

is( # vowels become 'y' and whitespace becomes '_'
    "ab\ncd\tef gh".trans(/<[aeiou]>/ => 'y', /\s/ => '_'),
    'yb_cd_yf_gh',
    'regexes pairs work',
);

if $subkinds ∋ 'method' { }

is('ababab'.trans([/ab/, 'aba', 'bab', /baba/] =>
                   ['1',  '2',   '3',   '4'   ]),
   '23',
   'longest token still holds, even between constant strings and regexes');

method info { [~] ' -- ', $.name,
                    (' [', @.vars»<name>.join(', '), ']' if @.vars) }

s[foo][bar $baz]
tr|a..c|A..C|;
$japh ~~ tr[a..zA..Z][n..za..mN..ZA..M];
tr/$123/X\x20\o40\t/;

ok("  a b\tc" ~~ m/@<chars>=( \s+ \S+ )+/, 'Named simple array capture');
ok("abcxyd" ~~ m/a  @<foo>=(.(.))+ d/, 'Repeated hypothetical array capture');
ok("  a b\tc" ~~ m/@<chars>=[ (<?spaces>) (\S+)]+/, 'Nested multiple array capture');

isa_ok(regex {oo}, Regex);
isa_ok(rx (o), Regex)
my @delims = < ^ ° ! " § $ % @ € & / = ? ` * + ~ ; , . | >;

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

Inf
-Inf
+Inf
NaN
-NaN
-3.340404
0.3
.3
100_000
1.2e7_000
1.2e-7

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

LABEL: for 0..$string.chars-1 -> $pos {
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

$foo.^method

say Buf.new(+«"127.0.0.1".split(".")).unpack("N")

[&sprintf]
X[&sprintf]
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

for ('/foo/bar/baz/' ~~ m/^ $<dirname>=(.* '/'+)? $<basename>=(<-[\/]>+) '/'* $ /).gist.lines {
    %count{$0}++ if / ^ \s+ (\w+) \s+ '=>' /;   ## extract key
};
throws_like "my Int a = 10;", X::Syntax::Malformed, message => / sigilless /;

my()
BEGIN()

# vim: ft=perl6
