
my $double = qq/foo $bar @baz[] bla/;
my $ex = qqx{foo $bar};
qx//;
q//
qw«hey there»
qww<yes 'no' foo>

my $hlagh = qq[foo bar $baz]
my $hlagh = q[foo bar $baz]

my $here = qto/foo/;
dsfsdfsdf
foo
say $here;

my $heredoc = qqto/foo bar/;
    dsfdsfsdfdsf
    dsfsdfsdfsd
    $foo
        sdfsdfsdfds
    foo bar

my %hih;

my @empty = <>;
my @empty = < >;


my $here = qq:to/GOO/
SDFSDF
sdfsdfsdf
sdfsdf
GOO

my $str = q:foo:heredoc:bar/bla/
dfgdfgdfg
dfg
bla

my $str = q:heredoc/bla/
dfgdfgdfg
dfg
bla

say qq :to 'TEXT';
    Wow, this is $description!
    TEXT

say qq
:to 'TEXT';
    Wow, this is $description!
    TEXT

# vim: ft=perl6
