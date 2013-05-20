sub _build_debugging_regex {
    s{
        (.*)
    }{
        # a comment!
    }eg;
}
