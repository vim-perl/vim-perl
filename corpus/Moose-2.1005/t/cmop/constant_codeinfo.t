use strict;
use warnings;
use Test::More;

use Class::MOP;

{
    package Foo;
    use constant FOO => 'bar';
}

my $meta = Class::MOP::Class->initialize('Foo');

my $syms = $meta->get_all_package_symbols('CODE');
is(ref $syms->{FOO}, 'CODE', 'get constant symbol');

undef $syms;

$syms = $meta->get_all_package_symbols('CODE');
is(ref $syms->{FOO}, 'CODE', 'constant symbol still there, although we dropped our reference');

done_testing;
