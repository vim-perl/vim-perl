token postfix:sym['->'] () { 
    '->'
    <!{ $*QSIGIL }>
    [
    | <brack=[ [ { ( ]> <.obs("'->" ~ $<brack>.Str ~ "' as postfix dereferencer", "'." ~ $<brack>.Str ~ "' or just '" ~ $<brack>.Str ~ "' to deref, or whitespace to delimit a pointy block")>
    | <.obs('-> as postfix', 'either . to call a method, or whitespace to delimit a pointy block')>
    ]
}

token sibble ($l, $lang2) {
    :my ($lang, $start, $stop);
    <babble($l)>
    { my $B = $<babble><B>; ($lang,$start,$stop) = @$B; }

    $start <left=.nibble($lang)> [ $stop || <.panic: "Couldn't find terminator $stop"> ]
    [ <?{ $start ne $stop }>
        <.ws>
        [ <?[ [ { ( < ]> <.obs('brackets around replacement', 'assignment syntax')> ]?
        [ <infixish> || <panic: "Missing assignment operator"> ]
        [ <?{ $<infixish>.Str eq '=' || $<infixish>.<infix_postfix_meta_operator>[0] }> || <.panic: "Malformed assignment operator"> ]
        <.ws>
        [ <right=EXPR(item %item_assignment)> || <.panic: "Assignment operator missing its expression"> ]
    ||.
        { $lang = $lang2.unbalanced($stop); }
        <right=.nibble($lang)> $stop || <.panic: "Malformed replacement part; couldn't find final $stop">
    ]
}

token TOP {
    <fred(1)>
    <fred: 2, 3>
}

ok('aaab' ~~ / "$!pattern" /, 'Interpolation of instance member');
ok("\x[c]\x[a]" ~~ m/<[\c[FORM FEED (FF), LINE FEED (LF)]]>/, 'Charclass multiple FORM FEED (FF), LINE FEED (LF)');
is('aaaaa' ~~ /<	a aa aaaa >/, 'aaaa', 'leading whitespace quotes words (tab)');

#ok("\c[DIGIT ZERO]" ~~ m/^<:bc<EN>>$/, q{Match (European Number)} );
#ok("abc" ~~ m/a(bc){$0 = uc $0}/, 'Numeric match');
#ok("abc" ~~ m/a(bc){make uc $0}/ , 'Zero match');
#'whatever' ~~ /w <test complicated . regex '<goes here>'>/;
#is('foo456bar' ~~ /foo <(\d+ bar/, '456bar', '<( match');
#is('foo123bar' ~~ /foo <( bar || ....../, 'foo123', '<( in backtracking');
#is('foo123bar' ~~ /foo <( 123 [ <( xyz ]?/, '123', 'multiple <( backtracking');
#ok(!( "a" ~~ m/(<[a..z]-[aeiou]>)/ ), 'Difference set failure');
#ok(!('a0' ~~ m/$aref[0]/), 'Array ref stringifies before matching'); #OK
#ok(!( "abcd f" ~~ m/abc <!before d <.ws> f>/ ), 'Negative lookahead failure');

# vim: ft=perl6
