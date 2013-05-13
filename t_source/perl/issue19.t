# vim:ft=perl

use strict;
use warnings;

m.foobar$.;
/foobar$/;
m#foobar$#;
m'foobar$';
m/foobar$/;
m(foobar$);
m{foobar$};
m<foobar$>;
m[foobar$];

s.foo.bar$.;
s.foo$.bar.;
s'foo'bar$';
s'foo$'bar';
s/foo/bar$/;
s/foo$/bar/;
s#foo#bar$#;
s#foo$#bar#;
s(foo)(bar$);
s(foo$)(bar);
s<foo><bar$>;
s<foo$><bar>;
s[foo][bar$];
s[foo$][bar];
s{foo}{bar$};
s{foo$}{bar};

tr/abc/def$/;
tr/abc$/def/;
y/abc/def$/;
y/abc$/def/;
tr.abc.def$.;
tr.abc$.def.;
y.abc.def$.;
y.abc$.def.;
tr#abc#def$#;
tr#abc$#def#;
y#abc#def$#;
y#abc$#def#;
tr[abc][def$];
tr[abc$][def];
y[abc][def$];
y[abc$][def];
tr(abc)(def$);
tr(abc$)(def);
y(abc)(def$);
y(abc$)(def);
tr<abc><def$>;
tr<abc$><def>;
y<abc><def$>;
y<abc$><def>;
tr{abc}{def$};
tr{abc$}{def};
y{abc}{def$};
y{abc$}{def};

print 'hi';
