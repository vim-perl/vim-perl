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

# vim: ft=perl6
