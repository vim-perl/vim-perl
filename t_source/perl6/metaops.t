use v6;

is 4 Rcmp 5, 5 cmp 4, "4 Rcmp 5";
isa_ok 4 Rcmp 5, (5 cmp 4).WHAT, "4 Rcmp 5 is the same type as 5 cmp 4";
is 4.3 Rcmp 5, 5 cmp 4.3, "4.3 Rcmp 5";
isa_ok 4.3 Rcmp 5, (5 cmp 4.3).WHAT, "4.3 Rcmp 5 is the same type as 5 cmp 4.3";
is 4.3 Rcmp 5.Num, 5.Num cmp 4.3, "4.3 Rcmp 5.Num";
isa_ok 4.3 Rcmp 5.Num, (5.Num cmp 4.3).WHAT, "4.3 Rcmp 5.Num is the same type as 5.Num cmp 4.3";
is 4.3i Rcmp 5.Num, 5.Num cmp 4.3i, "4.3i Rcmp 5.Num";
isa_ok 4.3i Rcmp 5.Num, (5.Num cmp 4.3i).WHAT, "4.3i Rcmp 5.Num is the same type as 5.Num cmp 4.3i";

is 4 R+ 5, 5 + 4, "4 R+ 5";
isa_ok 4 R+ 5, (5 + 4).WHAT, "4 R+ 5 is the same type as 5 + 4";
is 4 R- 5, 5 - 4, "4 R- 5";
isa_ok 4 R- 5, (5 - 4).WHAT, "4 R- 5 is the same type as 5 - 4";
is 4 R* 5, 5 * 4, "4 R* 5";
isa_ok 4 R* 5, (5 * 4).WHAT, "4 R* 5 is the same type as 5 * 4";
is 4 R/ 5, 5 / 4, "4 R/ 5";
isa_ok 4 R/ 5, (5 / 4).WHAT, "4 R/ 5 is the same type as 5 / 4";
is 4 Rdiv 5, 5 div 4, "4 Rdiv 5";
isa_ok 4 Rdiv 5, (5 div 4).WHAT, "4 Rdiv 5 is the same type as 5 div 4";
is 4 R% 5, 5 % 4, "4 R% 5";
isa_ok 4 R% 5, (5 % 4).WHAT, "4 R% 5 is the same type as 5 % 4";
is 4 R** 5, 5 ** 4, "4 R** 5";
isa_ok 4 R** 5, (5 ** 4).WHAT, "4 R** 5 is the same type as 5 ** 4";

is 4 R< 5, 5 < 4, "4 R< 5";
isa_ok 4 R< 5, (5 < 4).WHAT, "4 R< 5 is the same type as 5 < 4";
is 4 R> 5, 5 > 4, "4 R> 5";
isa_ok 4 R> 5, (5 > 4).WHAT, "4 R> 5 is the same type as 5 > 4";
is 4 R== 5, 5 == 4, "4 R== 5";
isa_ok 4 R== 5, (5 == 4).WHAT, "4 R== 5 is the same type as 5 == 4";
is 4 Rcmp 5, 5 cmp 4, "4 Rcmp 5";
isa_ok 4 Rcmp 5, (5 cmp 4).WHAT, "4 Rcmp 5 is the same type as 5 cmp 4";

is 3 R/ 9 + 5, 8, 'R/ gets precedence of /';
is 4 R- 5 R/ 10, -2, "Rop gets the precedence of op";
is (9 R... 1, 3), (1, 3, 5, 7, 9), "Rop gets list_infix precedence correctly";


{
    @r = (1, 2, 3) »+« (2, 4, 6);
    @e = (3, 6, 9);
    is(~@r, ~@e, "hyper-sum two arrays");

    @r = (1, 2, 3) »-« (2, 4, 6);
    @e = (-1, -2, -3);
    is(~@r, ~@e, "hyper-subtract two arrays");

    @r = (1, 2, 3) »*« (2, 4, 6);
    @e = (2, 8, 18);
    is(~@r, ~@e, "hyper-multiply two arrays");

    @r = (1, 2, 3) »x« (3, 2, 1);
    @e = ('111', '22', '3');
    is(~@r, ~@e, "hyper-x two arrays");

    @r = (1, 2, 3) »xx« (3, 2, 1);
    @e = ((1,1,1), (2,2), (3));
    is(~@r, ~@e, "hyper-xx two arrays");

    @r = (20, 40, 60) »div« (2, 5, 10);
    @e = (10, 8, 6);
    is(~@r, ~@e, "hyper-divide two arrays");

    @r = (1, 2, 3) »+« (10, 20, 30) »*« (2, 3, 4);
    @e = (21, 62, 123);
    is(~@r, ~@e, "precedence - »+« vs »*«");
}

{
    @r = (1, 2, 3) >>+<< (2, 4, 6);
    @e = (3, 6, 9);
    is(~@r, ~@e, "hyper-sum two arrays ASCII notation");

    @r = (1, 2, 3) >>-<< (2, 4, 6);
    @e = (-1, -2, -3);
    is(~@r, ~@e, "hyper-subtract two arrays ASCII notation");

    @r = (1, 2, 3) >>*<< (2, 4, 6);
    @e = (2, 8, 18);
    is(~@r, ~@e, "hyper-multiply two arrays ASCII notation");

    @r = (1, 2, 3) >>x<< (3, 2, 1);
    @e = ('111', '22', '3');
    is(~@r, ~@e, "hyper-x two arrays ASCII notation");

    @r = (1, 2, 3) >>xx<< (3, 2, 1);
    @e = ((1,1,1), (2,2), (3));
    is(~@r, ~@e, "hyper-xx two arrays ASCII notation");

    @r = (20, 40, 60) >>div<< (2, 5, 10);
    @e = (10, 8, 6);
    is(~@r, ~@e, "hyper-divide two arrays ASCII notation");

    @r = (1, 2, 3) >>+<< (10, 20, 30) >>*<< (2, 3, 4);
    @e = (21, 62, 123);
    is(~@r, ~@e, "precedence - >>+<< vs >>*<< ASCII notation");
};

{ # unary postfix
    my @r = (1, 2, 3);
    @r»++;
    my @e = (2, 3, 4);
    is(~@r, ~@e, "hyper auto increment an array");

    @r = (1, 2, 3);
    @r>>++;
    @e = (2, 3, 4);
    is(~@r, ~@e, "hyper auto increment an array ASCII notation");
};

{ # unary prefix
    my @r;
    @r = -« (3, 2, 1);
    my @e = (-3, -2, -1);
    is(~@r, ~@e, "hyper op on assignment/pipeline");

    @r = -<< (3, 2, 1);
    @e = (-3, -2, -1);
    is(~@r, ~@e, "hyper op on assignment/pipeline ASCII notation");
};

{ # dimension upgrade - ASCII
    my @r;
    @r = (1, 2, 3) >>+>> 1;
    my @e = (2, 3, 4);
    is(~@r, ~@e, "auto dimension upgrade on rhs ASCII notation");

    @r = 2 <<*<< (10, 20, 30);
    @e = (20, 40, 60);
    is(~@r, ~@e, "auto dimension upgrade on lhs ASCII notation");
}

{ # extension
    @r = (1,2,3,4) >>~>> <A B C D E>;
    @e = <1A 2B 3C 4D>;
    is(~@r, ~@e, "list-level element truncate on rhs ASCII notation");

    @r = (1,2,3,4,5) <<~<< <A B C D>;
    @e =  <1A 2B 3C 4D>;
    is(~@r, ~@e, "list-level element truncate on lhs ASCII notation");

    @r = (1,2,3,4) >>~>> <A B C>;
    @e = <1A 2B 3C 4A>;
    is(~@r, ~@e, "list-level element extension on rhs ASCII notation");

    @r = (1,2,3) <<~<< <A B C D>;
    @e =  <1A 2B 3C 1D>;
    is(~@r, ~@e, "list-level element extension on lhs ASCII notation");

    @r = (1,2,3,4) >>~>> <A B>;
    @e = <1A 2B 3A 4B>;
    is(~@r, ~@e, "list-level element extension on rhs ASCII notation");

    @r = (1,2) <<~<< <A B C D>;
    @e =  <1A 2B 1C 2D>;
    is(~@r, ~@e, "list-level element extension on lhs ASCII notation");

    @r = (1,2,3,4) >>~>> <A>;
    @e = <1A 2A 3A 4A>;
    is(~@r, ~@e, "list-level element extension on rhs ASCII notation");

    @r = (1,) <<~<< <A B C D>;
    @e = <1A 1B 1C 1D>;
    is(~@r, ~@e, "list-level element extension on lhs ASCII notation");

    @r = (1,2,3,4) >>~>> 'A';
    @e = <1A 2A 3A 4A>;
    is(~@r, ~@e, "scalar element extension on rhs ASCII notation");

    @r = 1 <<~<< <A B C D>;
    @e = <1A 1B 1C 1D>;
    is(~@r, ~@e, "scalar element extension on lhs ASCII notation");
};

{ # dimension upgrade - unicode
    @r = (1,2,3,4) »~» <A B C D E>;
    @e = <1A 2B 3C 4D>;
    is(~@r, ~@e, "list-level element truncate on rhs unicode notation");

    @r = (1,2,3,4,5) «~« <A B C D>;
    @e =  <1A 2B 3C 4D>;
    is(~@r, ~@e, "list-level element truncate on lhs unicode notation");

    @r = (1,2,3,4) »~» <A B C>;
    @e = <1A 2B 3C 4A>;
    is(~@r, ~@e, "list-level element extension on rhs unicode notation");

    @r = (1,2,3) «~« <A B C D>;
    @e =  <1A 2B 3C 1D>;
    is(~@r, ~@e, "list-level element extension on lhs unicode notation");

    @r = (1,2,3,4) »~» <A B>;
    @e = <1A 2B 3A 4B>;
    is(~@r, ~@e, "list-level element extension on rhs unicode notation");

    @r = (1,2) «~« <A B C D>;
    @e =  <1A 2B 1C 2D>;
    is(~@r, ~@e, "list-level element extension on lhs unicode notation");

    @r = (1,2,3,4) »~» <A>;
    @e = <1A 2A 3A 4A>;
    is(~@r, ~@e, "list-level element extension on rhs unicode notation");

    @r = (1,) «~« <A B C D>;
    @e = <1A 1B 1C 1D>;
    is(~@r, ~@e, "list-level element extension on lhs unicode notation");

    @r = (1,2,3,4) »~» 'A';
    @e = <1A 2A 3A 4A>;
    is(~@r, ~@e, "scalar element extension on rhs unicode notation");

    @r = 1 «~« <A B C D>;
    @e = <1A 1B 1C 1D>;
    is(~@r, ~@e, "scalar element extension on lhs unicode notation");
};

{ # unary postfix with integers
    my @r;
    @r = (1, 4, 9)».sqrt;
    my @e = (1, 2, 3);
    is(~@r, ~@e, "method call on integer list elements");

    @r = (1, 4, 9)>>.sqrt;
    @e = (1, 2, 3);
    is(~@r, ~@e, "method call on integer list elements (ASCII)");
}

{
    my (@r, @e);
    (@r = (1, 4, 9))»++;
    @e = (2, 5, 10);
    is(~@r, ~@e, "operator call on integer list elements");

    (@r = (1, 4, 9)).»++;
    is(~@r, ~@e, "operator call on integer list elements (Same thing, dot form)");
}

# RT #122342
{
    my (@r, @e);
    @e = (2, 5, 10);

    (@r = (1, 4, 9)).».++;
    is(~@r, ~@e, "postfix operator (dotted form) on integer list elements after unary postfix hyper operator");

    (@r = (1, 4, 9)).>>.++;
    is(~@r, ~@e, "postfix operator (dotted form) on integer list elements after unary postfix hyper operator (ASCII)");

    (@r = (1, 4, 9))\  .»\  .++;
    @e = (2, 5, 10);
    is(~@r, ~@e, "postfix operator (dotted form) on integer list elements after unary postfix hyper operator (unspace form)");
}

{
  my @array = <5 -3 7 0 1 -9>;
  my $sum   = 5 + -3 + 7 + 0 + 1 + -9; # laziness :)

  is(([+] @array),      $sum, "[+] works");
  is(([*]  1,2,3),    (1*2*3), "[*] works");
  is(([-]  1,2,3),    (1-2-3), "[-] works");
  is(([/]  12,4,3),  (12/4/3), "[/] works");
  is(([div]  12,4,3),  (12 div 4 div 3), "[div] works");
  is(([**] 2,2,3),  (2**2**3), "[**] works");
  is(([%]  13,7,4), (13%7%4),  "[%] works");
  is(([mod]  13,7,4), (13 mod 7 mod 4),  "[mod] works");

  is((~ [\+] @array), "5 2 9 9 10 1", "[\\+] works");
  is((~ [\-] 1, 2, 3), "1 -1 -4",      "[\\-] works");
}

{
  is ([~] <a b c d>), "abcd", "[~] works";
  is (~ [\~] <a b c d>), "a ab abc abcd", "[\\~] works";
}

{
    ok  ([<]  1, 2, 3, 4), "[<] works (1)";
    nok ([<]  1, 3, 2, 4), "[<] works (2)";
    ok  ([>]  4, 3, 2, 1), "[>] works (1)";
    nok ([>]  4, 2, 3, 1), "[>] works (2)";
    ok  ([==] 4, 4, 4),    "[==] works (1)";
    nok ([==] 4, 5, 4),    "[==] works (2)";
    #?niecza 2 skip 'this is parsed as ![=], not good'
    ok  ([!=] 4, 5, 6),    "[!=] works (1)";
    nok ([!=] 4, 4, 4),    "[!=] works (2)";
}

{
    ok (! [eq] <a a b a>),    '[eq] basic sanity (positive)';
    ok (  [eq] <a a a a>),    '[eq] basic sanity (negative)';
    ok (  [ne] <a b c a>),    '[ne] basic sanity (positive)';
    ok (! [ne] <a a b c>),    '[ne] basic sanity (negative)';
    ok (  [lt] <a b c e>),    '[lt] basic sanity (positive)';
    ok (! [lt] <a a c e>),    '[lt] basic sanity (negative)';
}

{
    my ($x, $y);
    #?rakudo todo 'huh?'
    ok (    [=:=]  $x, $x, $x), '[=:=] basic sanity 1';
    ok (not [=:=]  $x, $y, $x), '[=:=] basic sanity 2';
    ok (    [!=:=] $x, $y, $x), '[!=:=] basic sanity (positive)';
    #?rakudo todo 'huh?'
    ok (not [!=:=] $y, $y, $x), '[!=:=] basic sanity (negative)';
    $y := $x;
    #?rakudo todo 'huh?'
    ok (    [=:=]  $y, $x, $y), '[=:=] after binding';
}

{
    my $a = [1, 2];
    my $b = [1, 2];

    ok  ([===] 1, 1, 1, 1),      '[===] with literals';
    ok  ([===] $a, $a, $a),      '[===] with vars (positive)';
    nok ([===] $a, $a, [1, 2]),  '[===] with vars (negative)';
    ok  ([!===] $a, $b, $a),     '[!===] basic sanity (positive)';
    nok ([!===] $a, $b, $b),     '[!===] basic sanity (negative)';
}

{
    is ~ ([\<]  1, 2, 3, 4).map({+$_}), "1 1 1 1", "[\\<] works (1)";
    is ~ ([\<]  1, 3, 2, 4).map({+$_}), "1 1 0 0", "[\\<] works (2)";
    is ~ ([\>]  4, 3, 2, 1).map({+$_}), "1 1 1 1", "[\\>] works (1)";
    is ~ ([\>]  4, 2, 3, 1).map({+$_}), "1 1 0 0", "[\\>] works (2)";
    is ~ ([\==]  4, 4, 4).map({+$_}),   "1 1 1",   "[\\==] works (1)";
    is ~ ([\==]  4, 5, 4).map({+$_}),   "1 0 0",   "[\\==] works (2)";
    #?niecza 2 todo 'this is parsed as ![=], not good'
    is ~ ([\!=]  4, 5, 6).map({+$_}),   "1 1 1",   "[\\!=] works (1)";
    is ~ ([\!=]  4, 5, 5).map({+$_}),   "1 1 0",   "[\\!=] works (2)";
    is (~ [\**]  1, 2, 3),   "3 8 1",   "[\\**] (right assoc) works (1)";
    is (~ [\**]  3, 2, 0),   "0 1 3",   "[\\**] (right assoc) works (2)";
}

# RT #76110
{
    is ~([\+] [\+] 1 xx 5), '1 3 6 10 15', 'two nested [\+]';
    #?niecza todo 'unary [] does not context yet'
    is ([+] [1, 2, 3, 4]), 4,  '[+] does not flatten []-arrays';
}

#?niecza skip '[macro]'
{
  my @array = (Mu, Mu, 3, Mu, 5);
  is ([//]  @array), 3, "[//] works";
  is ([orelse] @array), 3, "[orelse] works";
}

#?niecza skip '[macro]'
{
  my @array = (Mu, Mu, 0, 3, Mu, 5);
  is ([||] @array), 3, "[||] works";
  is ([or] @array), 3, "[or] works";

  # Mu as well as [//] should work too, but testing it like
  # this would presumably emit warnings when we have them.
  is (~ [\||] 0, 0, 3, 4, 5), "0 0 3 3 3", "[\\||] works";
}

# vim: ft=perl6
