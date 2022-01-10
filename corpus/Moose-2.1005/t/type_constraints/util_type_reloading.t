#!/usr/bin/perl

use strict;
use warnings;

use lib 't/lib', 'lib';

use Test::More;


$SIG{__WARN__} = sub { 0 };

eval { require Foo; };
ok(!$@, '... loaded Foo successfully') || diag $@;

delete $INC{'Foo.pm'};

eval { require Foo; };
ok(!$@, '... re-loaded Foo successfully') || diag $@;

eval { require Bar; };
ok(!$@, '... loaded Bar successfully') || diag $@;

delete $INC{'Bar.pm'};

eval { require Bar; };
ok(!$@, '... re-loaded Bar successfully') || diag $@;

done_testing;
