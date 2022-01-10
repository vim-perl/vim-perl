#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use Class::MOP;
my $non = Class::MOP::Class->initialize('Non::Existent::Package');
$non->get_method('foo');

pass("empty stashes don't segfault");

done_testing;
