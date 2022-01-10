#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::Fatal;
use Test::Moose;

BEGIN {
    package ExportsFoo;
    use Sub::Exporter -setup => {
        exports => ['foo'],
    };

    sub foo { 'FOO' }

    $INC{'ExportsFoo.pm'} = 1;
}

{
    package Foo;
    use Moose::Role;
    requires 'foo';
}

{
    package Bar;
    use Moose::Role;
    requires 'bar';
}

{
    package Class;
    use Moose;
    use ExportsFoo 'foo';

    # The grossness near the end of the regex works around a bug with \Q not
    # escaping \& properly with perl 5.8.x
    ::like(
        ::exception { with 'Foo' },
        qr/^\Q'Foo' requires the method 'foo' to be implemented by 'Class'. If you imported functions intending to use them as methods, you need to explicitly mark them as such, via Class->meta->add_method(foo => \E\\\&foo\)/,
        "imported 'method' isn't seen"
    );
    Class->meta->add_method(foo => \&foo);
    ::is(
        ::exception { with 'Foo' },
        undef,
        "now it's a method"
    );

    ::like(
        ::exception { with 'Bar' },
        qr/^\Q'Bar' requires the method 'bar' to be implemented by 'Class' at/,
        "requirement isn't imported, so don't give the extra info in the error"
    );
}

does_ok('Class', 'Foo');

done_testing;
