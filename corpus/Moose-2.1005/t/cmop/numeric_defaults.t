#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use B;
use Class::MOP;

my @int_defaults = (
    100,
    -2,
    01234,
    0xFF,
);

my @num_defaults = (
    10.5,
    -20.0,
    1e3,
    1.3e-10,
);

my @string_defaults = (
    'foo',
    '',
    '100',
    '10.5',
    '1e3',
    '0 but true',
    '01234',
    '09876',
    '0xFF',
);

for my $default (@int_defaults) {
    my $copy = $default; # so we can print it out without modifying flags
    my $attr = Class::MOP::Attribute->new(
        foo => (default => $default, reader => 'foo'),
    );
    my $meta = Class::MOP::Class->create_anon_class(
        attributes => [$attr],
        methods    => {bar => sub { $default }},
    );

    my $obj = $meta->new_object;
    for my $meth (qw(foo bar)) {
        my $val = $obj->$meth;
        my $b = B::svref_2object(\$val);
        my $flags = $b->FLAGS;
        ok($flags & B::SVf_IOK || $flags & B::SVp_IOK, "it's an int ($copy)");
        ok(!($flags & B::SVf_POK), "not a string ($copy)");
    }

    $meta->make_immutable;

    my $immutable_obj = $meta->name->new;
    for my $meth (qw(foo bar)) {
        my $val = $immutable_obj->$meth;
        my $b = B::svref_2object(\$val);
        my $flags = $b->FLAGS;
        ok($flags & B::SVf_IOK || $flags & B::SVp_IOK, "it's an int ($copy) (immutable)");
        ok(!($flags & B::SVf_POK), "not a string ($copy) (immutable)");
    }
}

for my $default (@num_defaults) {
    my $copy = $default; # so we can print it out without modifying flags
    my $attr = Class::MOP::Attribute->new(
        foo => (default => $default, reader => 'foo'),
    );
    my $meta = Class::MOP::Class->create_anon_class(
        attributes => [$attr],
        methods    => {bar => sub { $default }},
    );

    my $obj = $meta->new_object;
    for my $meth (qw(foo bar)) {
        my $val = $obj->$meth;
        my $b = B::svref_2object(\$val);
        my $flags = $b->FLAGS;
        ok($flags & B::SVf_NOK || $flags & B::SVp_NOK, "it's a num ($copy)");
        ok(!($flags & B::SVf_POK), "not a string ($copy)");
    }

    $meta->make_immutable;

    my $immutable_obj = $meta->name->new;
    for my $meth (qw(foo bar)) {
        my $val = $immutable_obj->$meth;
        my $b = B::svref_2object(\$val);
        my $flags = $b->FLAGS;
        ok($flags & B::SVf_NOK || $flags & B::SVp_NOK, "it's a num ($copy) (immutable)");
        ok(!($flags & B::SVf_POK), "not a string ($copy) (immutable)");
    }
}

for my $default (@string_defaults) {
    my $copy = $default; # so we can print it out without modifying flags
    my $attr = Class::MOP::Attribute->new(
        foo => (default => $default, reader => 'foo'),
    );
    my $meta = Class::MOP::Class->create_anon_class(
        attributes => [$attr],
        methods    => {bar => sub { $default }},
    );

    my $obj = $meta->new_object;
    for my $meth (qw(foo bar)) {
        my $val = $obj->$meth;
        my $b = B::svref_2object(\$val);
        my $flags = $b->FLAGS;
        ok($flags & B::SVf_POK, "it's a string ($copy)");
    }

    $meta->make_immutable;

    my $immutable_obj = $meta->name->new;
    for my $meth (qw(foo bar)) {
        my $val = $immutable_obj->$meth;
        my $b = B::svref_2object(\$val);
        my $flags = $b->FLAGS;
        ok($flags & B::SVf_POK, "it's a string ($copy) (immutable)");
    }
}

done_testing;
