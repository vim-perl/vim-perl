#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::Fatal;

use Moose::Util::TypeConstraints;

{
    package Types;
    use Moose::Util::TypeConstraints;

    type 'Foo1';
    subtype 'Foo2', as 'Str';
    class_type 'Foo3';
    role_type 'Foo4';

    { package Foo5;     use Moose; }
    { package Foo6;     use Moose::Role; }
    { package IsaAttr;  use Moose; has foo => (is => 'ro', isa  => 'Foo7'); }
    { package DoesAttr; use Moose; has foo => (is => 'ro', does => 'Foo8'); }
}

{
    my $anon = 0;
    my @checks = (
        [1, sub { type $_[0] }, 'type'],
        [1, sub { subtype $_[0], as 'Str' }, 'subtype'],
        [1, sub { class_type $_[0] }, 'class_type'],
        [1, sub { role_type $_[0] }, 'role_type'],
        # should these two die?
        [0, sub { eval "package $_[0]; use Moose; 1" || die $@ }, 'use Moose'],
        [0, sub { eval "package $_[0]; use Moose::Role; 1" || die $@ }, 'use Moose::Role'],
        [0, sub {
            $anon++;
            eval <<CLASS || die $@;
            package Anon$anon;
            use Moose;
            has foo => (is => 'ro', isa => '$_[0]');
            1
CLASS
        }, 'isa => "Thing"'],
        [0, sub {
            $anon++;
            eval <<CLASS || die $@;
            package Anon$anon;
            use Moose;
            has foo => (is => 'ro', does => '$_[0]');
            1
CLASS
        }, 'does => "Thing"'],
    );

    sub check_conflicts {
        my ($type_name) = @_;
        my $type = find_type_constraint($type_name);
        for my $check (@checks) {
            my ($should_fail, $code, $desc) = @$check;

            $should_fail = 0
                if overriding_with_equivalent_type($type, $desc);
            unload_class($type_name);

            if ($should_fail) {
                like(
                    exception { $code->($type_name) },
                    qr/^The type constraint '$type_name' has already been created in [\w:]+ and cannot be created again in [\w:]+/,
                    "trying to override $type_name via '$desc' should die"
                );
            }
            else {
                is(
                    exception { $code->($type_name) },
                    undef,
                    "trying to override $type_name via '$desc' should do nothing"
                );
            }
            is($type, find_type_constraint($type_name), "type didn't change");
        }
    }

    sub unload_class {
        my ($class) = @_;
        my $meta = Class::MOP::class_of($class);
        return unless $meta;
        $meta->add_package_symbol('@ISA', []);
        $meta->remove_package_symbol('&'.$_)
            for $meta->list_all_package_symbols('CODE');
        undef $meta;
        Class::MOP::remove_metaclass_by_name($class);
    }

    sub overriding_with_equivalent_type {
        my ($type, $desc) = @_;
        if ($type->isa('Moose::Meta::TypeConstraint::Class')) {
            return 1 if $desc eq 'use Moose'
                     || $desc eq 'class_type'
                     || $desc eq 'isa => "Thing"';
        }
        if ($type->isa('Moose::Meta::TypeConstraint::Role')) {
            return 1 if $desc eq 'use Moose::Role'
                     || $desc eq 'role_type'
                     || $desc eq 'does => "Thing"';
        }
        return;
    }
}

{
    check_conflicts($_) for map { "Foo$_" } 1..8;
}

done_testing;
