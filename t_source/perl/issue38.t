# vim:ft=perl

use strict;
use warnings;

print qq{<a href="$h{var}">}, '$this_is_not_interpreted';
print qq[<a href="$h[0]">], '$this_is_not_interpreted';
print qq[<a href="$h[$f]">], '$this_is_not_interpreted';
