#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::Fatal;
use Test::Moose;

{
    package ValueContainer;
    use Moose;

    has value => (
        is => 'rw',
    );
}

{
    package Foo::Meta::Instance;
    use Moose::Role;

    around get_slot_value => sub {
        my $orig = shift;
        my $self = shift;
        my ($instance, $slot_name) = @_;
        my $value = $self->$orig(@_);
        if ($value->isa('ValueContainer')) {
            $value = $value->value;
        }
        return $value;
    };

    around inline_get_slot_value => sub {
        my $orig = shift;
        my $self = shift;
        my $value = $self->$orig(@_);
        return q[do {] . "\n"
             . q[    my $value = ] . $value . q[;] . "\n"
             . q[    if ($value->isa('ValueContainer')) {] . "\n"
             . q[        $value = $value->value;] . "\n"
             . q[    }] . "\n"
             . q[    $value] . "\n"
             . q[}];
    };

    sub inline_get_is_lvalue { 0 }
}

{
    package Foo;
    use Moose;
    Moose::Util::MetaRole::apply_metaroles(
        for => __PACKAGE__,
        class_metaroles => {
            instance => ['Foo::Meta::Instance'],
        }
    );

    ::is( ::exception {
        has array => (
            traits  => ['Array'],
            isa     => 'ArrayRef',
            default => sub { [] },
            handles => {
                array_count              => 'count',
                array_elements           => 'elements',
                array_is_empty           => 'is_empty',
                array_push               => 'push',
                array_push_curried       => [ push => 42, 84 ],
                array_unshift            => 'unshift',
                array_unshift_curried    => [ unshift => 42, 84 ],
                array_pop                => 'pop',
                array_shift              => 'shift',
                array_get                => 'get',
                array_get_curried        => [ get => 1 ],
                array_set                => 'set',
                array_set_curried_1      => [ set => 1 ],
                array_set_curried_2      => [ set => ( 1, 98 ) ],
                array_accessor           => 'accessor',
                array_accessor_curried_1 => [ accessor => 1 ],
                array_accessor_curried_2 => [ accessor => ( 1, 90 ) ],
                array_clear              => 'clear',
                array_delete             => 'delete',
                array_delete_curried     => [ delete => 1 ],
                array_insert             => 'insert',
                array_insert_curried     => [ insert => ( 1, 101 ) ],
                array_splice             => 'splice',
                array_splice_curried_1   => [ splice => 1 ],
                array_splice_curried_2   => [ splice => 1, 2 ],
                array_splice_curried_all => [ splice => 1, 2, ( 3, 4, 5 ) ],
                array_sort               => 'sort',
                array_sort_curried       =>
                    [ sort => ( sub { $_[1] <=> $_[0] } ) ],
                array_sort_in_place      => 'sort_in_place',
                array_sort_in_place_curried =>
                    [ sort_in_place => ( sub { $_[1] <=> $_[0] } ) ],
                array_map                => 'map',
                array_map_curried        => [ map => ( sub { $_ + 1 } ) ],
                array_grep               => 'grep',
                array_grep_curried       => [ grep => ( sub { $_ < 5 } ) ],
                array_first              => 'first',
                array_first_curried      => [ first => ( sub { $_ % 2 } ) ],
                array_join               => 'join',
                array_join_curried       => [ join => '-' ],
                array_shuffle            => 'shuffle',
                array_uniq               => 'uniq',
                array_reduce             => 'reduce',
                array_reduce_curried     =>
                    [ reduce => ( sub { $_[0] * $_[1] } ) ],
                array_natatime           => 'natatime',
                array_natatime_curried   => [ natatime => 2 ],
            },
        );
    }, undef, "native array trait inlines properly" );

    ::is( ::exception {
        has bool => (
            traits  => ['Bool'],
            isa     => 'Bool',
            default => 0,
            handles => {
                bool_illuminate  => 'set',
                bool_darken      => 'unset',
                bool_flip_switch => 'toggle',
                bool_is_dark     => 'not',
            },
        );
    }, undef, "native bool trait inlines properly" );

    ::is( ::exception {
        has code => (
            traits  => ['Code'],
            isa     => 'CodeRef',
            default => sub { sub { } },
            handles => {
                code_execute        => 'execute',
                code_execute_method => 'execute_method',
            },
        );
    }, undef, "native code trait inlines properly" );

    ::is( ::exception {
        has counter => (
            traits  => ['Counter'],
            isa     => 'Int',
            default => 0,
            handles => {
                inc_counter    => 'inc',
                inc_counter_2  => [ inc => 2 ],
                dec_counter    => 'dec',
                dec_counter_2  => [ dec => 2 ],
                reset_counter  => 'reset',
                set_counter    => 'set',
                set_counter_42 => [ set => 42 ],
            },
        );
    }, undef, "native counter trait inlines properly" );

    ::is( ::exception {
        has hash => (
            traits  => ['Hash'],
            isa     => 'HashRef',
            default => sub { {} },
            handles => {
                hash_option_accessor  => 'accessor',
                hash_quantity         => [ accessor => 'quantity' ],
                hash_clear_options    => 'clear',
                hash_num_options      => 'count',
                hash_delete_option    => 'delete',
                hash_is_defined       => 'defined',
                hash_options_elements => 'elements',
                hash_has_option       => 'exists',
                hash_get_option       => 'get',
                hash_has_no_options   => 'is_empty',
                hash_key_value        => 'kv',
                hash_set_option       => 'set',
            },
        );
    }, undef, "native hash trait inlines properly" );

    ::is( ::exception {
        has number => (
            traits  => ['Number'],
            isa     => 'Num',
            default => 0,
            handles => {
                num_abs         => 'abs',
                num_add         => 'add',
                num_inc         => [ add => 1 ],
                num_div         => 'div',
                num_cut_in_half => [ div => 2 ],
                num_mod         => 'mod',
                num_odd         => [ mod => 2 ],
                num_mul         => 'mul',
                num_set         => 'set',
                num_sub         => 'sub',
                num_dec         => [ sub => 1 ],
            },
        );
    }, undef, "native number trait inlines properly" );

    ::is( ::exception {
        has string => (
            traits  => ['String'],
            is      => 'ro',
            isa     => 'Str',
            default => '',
            handles => {
                string_inc             => 'inc',
                string_append          => 'append',
                string_append_curried  => [ append => '!' ],
                string_prepend         => 'prepend',
                string_prepend_curried => [ prepend => '-' ],
                string_replace         => 'replace',
                string_replace_curried => [ replace => qr/(.)$/, sub { uc $1 } ],
                string_chop            => 'chop',
                string_chomp           => 'chomp',
                string_clear           => 'clear',
                string_match           => 'match',
                string_match_curried    => [ match  => qr/\D/ ],
                string_length           => 'length',
                string_substr           => 'substr',
                string_substr_curried_1 => [ substr => (1) ],
                string_substr_curried_2 => [ substr => ( 1, 3 ) ],
                string_substr_curried_3 => [ substr => ( 1, 3, 'ong' ) ],
            },
        );
    }, undef, "native string trait inlines properly" );
}

with_immutable {
    {
        my $foo = Foo->new(string => 'a');
        is($foo->string, 'a');
        $foo->string_append('b');
        is($foo->string, 'ab');
    }

    {
        my $foo = Foo->new(string => '');
        $foo->{string} = ValueContainer->new(value => 'a');
        is($foo->string, 'a');
        $foo->string_append('b');
        is($foo->string, 'ab');
    }
} 'Foo';

done_testing;
