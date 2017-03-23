#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use Test::Requires {
    'Test::Output' => '0.01',    # skip all if not installed
};

{

    package Foo;
    use Moose;

    sub get_a   { }
    sub set_b   { }
    sub has_c   { }
    sub clear_d { }
    sub e       { }
    sub stub;
}

my $foo_meta = Foo->meta;
stderr_like(
    sub { $foo_meta->add_attribute( a => ( reader => 'get_a' ) ) },
    qr/^You are overwriting a locally defined method \(get_a\) with an accessor/,
    'reader overriding gives proper warning'
);
stderr_like(
    sub { $foo_meta->add_attribute( b => ( writer => 'set_b' ) ) },
    qr/^You are overwriting a locally defined method \(set_b\) with an accessor/,
    'writer overriding gives proper warning'
);
stderr_like(
    sub { $foo_meta->add_attribute( c => ( predicate => 'has_c' ) ) },
    qr/^You are overwriting a locally defined method \(has_c\) with an accessor/,
    'predicate overriding gives proper warning'
);
stderr_like(
    sub { $foo_meta->add_attribute( d => ( clearer => 'clear_d' ) ) },
    qr/^You are overwriting a locally defined method \(clear_d\) with an accessor/,
    'clearer overriding gives proper warning'
);
stderr_like(
    sub { $foo_meta->add_attribute( e => ( is => 'rw' ) ) },
    qr/^You are overwriting a locally defined method \(e\) with an accessor/,
    'accessor overriding gives proper warning'
);
stderr_is(
    sub { $foo_meta->add_attribute( stub => ( is => 'rw' ) ) },
    q{},
    'overriding a stub with an accessor does not warn'
);
stderr_like(
    sub { $foo_meta->add_attribute( has => ( is => 'rw' ) ) },
    qr/^You are overwriting a locally defined function \(has\) with an accessor/,
    'function overriding gives proper warning'
);

done_testing;
