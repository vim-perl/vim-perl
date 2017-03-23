#!/usr/bin/perl

use strict;
use warnings;

use Test::More;


=pod

See this for some details:

http://bugs.debian.org/cgi-bin/bugreport.cgi?bug=476579

Here is the basic test case, it segfaults, so I am going
to leave it commented out. Basically it seems that there
is some bad interaction between the ??{} construct that
is used in the "parser" for type definitions and threading
so probably the fix would involve removing the ??{} usage
for something else.

use threads;

{
    package Foo;
    use Moose;
    has "bar" => (is => 'rw', isa => "Str | Num");
}

my $thr = threads->create(sub {});
$thr->join();

=cut

{
    local $TODO = 'This is just a stub for the test, see the POD';
    fail('Moose type constraints and threads dont get along');
}

done_testing;
