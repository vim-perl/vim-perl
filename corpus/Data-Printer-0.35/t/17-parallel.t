use strict;
use warnings;
BEGIN {
    delete $ENV{DATAPRINTERRC};
    use File::HomeDir::Test;  # avoid user's .dataprinter
    use Term::ANSIColor;
};

package Foo;
use Data::Printer { colored => 1, color => { number => 'green' } };
sub foo { p($_[0]) }

package Bar;
use Data::Printer { colored => 1, color => { number => 'yellow' } };

sub bar { p($_[0]) }

package main;
use Test::More;
use Data::Printer { colored => 1, color => { number => 'blue' } };
delete $ENV{ANSI_COLORS_DISABLED};

my $data = 42;

plan skip_all => 'failed color sanity check'
    if $data eq colored($data, 'blue');

# IMPORTANT NOTE:
# this "overriding" was because I felt the final
# user should be the one deciding how to output
# the data. These "nested custom dumps" looks to me
# like something quite rare and unlikely to happen
# in the Real World (tm). But if you have a
# compelling argument on why this behavior should
# change, please drop me a line - but note that you
# *CAN* customize Data::Printer within modules
# simply by overriding any options when calling p()

is(p($data), color('reset') . colored($data, 'blue'),
   'main::p should be blue'
);

is(Foo::foo($data), color('reset') . colored($data, 'blue'),
   'main overrides customization in Foo'
);

is(Bar::bar($data), color('reset') . colored($data, 'blue'),
   'main overrides customization in Bar'
);


done_testing;
