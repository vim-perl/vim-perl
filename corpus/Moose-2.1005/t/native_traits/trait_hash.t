#!/usr/bin/perl

use strict;
use warnings;

use lib 't/lib';

use Moose ();
use Moose::Util::TypeConstraints;
use NoInlineAttribute;
use Test::Fatal;
use Test::More;
use Test::Moose;

{
    my %handles = (
        option_accessor  => 'accessor',
        quantity         => [ accessor => 'quantity' ],
        clear_options    => 'clear',
        num_options      => 'count',
        delete_option    => 'delete',
        is_defined       => 'defined',
        options_elements => 'elements',
        has_option       => 'exists',
        get_option       => 'get',
        has_no_options   => 'is_empty',
        keys             => 'keys',
        values           => 'values',
        key_value        => 'kv',
        set_option       => 'set',
    );

    my $name = 'Foo1';

    sub build_class {
        my %attr = @_;

        my $class = Moose::Meta::Class->create(
            $name++,
            superclasses => ['Moose::Object'],
        );

        my @traits = 'Hash';
        push @traits, 'NoInlineAttribute'
            if delete $attr{no_inline};

        $class->add_attribute(
            options => (
                traits  => \@traits,
                is      => 'rw',
                isa     => 'HashRef[Str]',
                default => sub { {} },
                handles => \%handles,
                clearer => '_clear_options',
                %attr,
            ),
        );

        return ( $class->name, \%handles );
    }
}

{
    run_tests(build_class);
    run_tests( build_class( lazy => 1, default => sub { { x => 1 } } ) );
    run_tests( build_class( trigger => sub { } ) );
    run_tests( build_class( no_inline => 1 ) );

    # Will force the inlining code to check the entire hashref when it is modified.
    subtype 'MyHashRef', as 'HashRef[Str]', where { 1 };

    run_tests( build_class( isa => 'MyHashRef' ) );

    coerce 'MyHashRef', from 'HashRef', via { $_ };

    run_tests( build_class( isa => 'MyHashRef', coerce => 1 ) );
}

sub run_tests {
    my ( $class, $handles ) = @_;

    can_ok( $class, $_ ) for sort keys %{$handles};

    with_immutable {
        my $obj = $class->new( options => {} );

        ok( $obj->has_no_options, '... we have no options' );
        is( $obj->num_options, 0, '... we have no options' );

        is_deeply( $obj->options, {}, '... no options yet' );
        ok( !$obj->has_option('foo'), '... we have no foo option' );

        is( exception {
            is(
                $obj->set_option( foo => 'bar' ),
                'bar',
                'set return single new value in scalar context'
            );
        }, undef, '... set the option okay' );

        like(
            exception { $obj->set_option( foo => 'bar', 'baz' ) },
            qr/You must pass an even number of arguments to set/,
            'exception with odd number of arguments'
        );

        like(
            exception { $obj->set_option( undef, 'bar' ) },
            qr/Hash keys passed to set must be defined/,
            'exception when using undef as a key'
        );

        ok( $obj->is_defined('foo'), '... foo is defined' );

        ok( !$obj->has_no_options, '... we have options' );
        is( $obj->num_options, 1, '... we have 1 option(s)' );
        ok( $obj->has_option('foo'), '... we have a foo option' );
        is_deeply( $obj->options, { foo => 'bar' }, '... got options now' );

        is( exception {
            $obj->set_option( bar => 'baz' );
        }, undef, '... set the option okay' );

        is( $obj->num_options, 2, '... we have 2 option(s)' );
        is_deeply(
            $obj->options, { foo => 'bar', bar => 'baz' },
            '... got more options now'
        );

        is( $obj->get_option('foo'), 'bar', '... got the right option' );

        is_deeply(
            [ $obj->get_option(qw(foo bar)) ], [qw(bar baz)],
            "get multiple options at once"
        );

        is(
            scalar( $obj->get_option(qw( foo bar)) ), "baz",
            '... got last option in scalar context'
        );

        is( exception {
            $obj->set_option( oink => "blah", xxy => "flop" );
        }, undef, '... set the option okay' );

        is( $obj->num_options, 4, "4 options" );
        is_deeply(
            [ $obj->get_option(qw(foo bar oink xxy)) ],
            [qw(bar baz blah flop)], "get multiple options at once"
        );

        is( exception {
            is( scalar $obj->delete_option('bar'), 'baz',
                'delete returns deleted value' );
        }, undef, '... deleted the option okay' );

        is( exception {
            is_deeply(
                [ $obj->delete_option( 'oink', 'xxy' ) ],
                [ 'blah', 'flop' ],
                'delete returns all deleted values in list context'
            );
        }, undef, '... deleted multiple option okay' );

        is( $obj->num_options, 1, '... we have 1 option(s)' );
        is_deeply(
            $obj->options, { foo => 'bar' },
            '... got more options now'
        );

        $obj->clear_options;

        is_deeply( $obj->options, {}, "... cleared options" );

        is( exception {
            $obj->quantity(4);
        }, undef, '... options added okay with defaults' );

        is( $obj->quantity, 4, 'reader part of curried accessor works' );

        is(
            $obj->option_accessor('quantity'), 4,
            'accessor as reader'
        );

        is_deeply(
            $obj->options, { quantity => 4 },
            '... returns what we expect'
        );

        $obj->option_accessor( size => 42 );

        like(
            exception {
                $obj->option_accessor;
            },
            qr/Cannot call accessor without at least 1 argument/,
            'error when calling accessor with no arguments'
        );

        like(
            exception { $obj->option_accessor( undef, 'bar' ) },
            qr/Hash keys passed to accessor must be defined/,
            'exception when using undef as a key'
        );

        is_deeply(
            $obj->options, { quantity => 4, size => 42 },
            'accessor as writer'
        );

        is( exception {
            $class->new( options => { foo => 'BAR' } );
        }, undef, '... good constructor params' );

        isnt( exception {
            $obj->set_option( bar => {} );
        }, undef, '... could not add a hash ref where an string is expected' );

        isnt( exception {
            $class->new( options => { foo => [] } );
        }, undef, '... bad constructor params' );

        $obj->options( {} );

        is_deeply(
            [ $obj->set_option( oink => "blah", xxy => "flop" ) ],
            [ 'blah', 'flop' ],
            'set returns newly set values in order of keys provided'
        );

        is_deeply(
            [ sort $obj->keys ],
            [ 'oink', 'xxy' ],
            'keys returns expected keys'
        );

        is_deeply(
            [ sort $obj->values ],
            [ 'blah', 'flop' ],
            'values returns expected values'
        );

        my @key_value = sort { $a->[0] cmp $b->[0] } $obj->key_value;
        is_deeply(
            \@key_value,
            [
                sort { $a->[0] cmp $b->[0] }[ 'xxy', 'flop' ],
                [ 'oink',     'blah' ]
            ],
            '... got the right key value pairs'
            )
            or do {
            require Data::Dumper;
            diag( Data::Dumper::Dumper( \@key_value ) );
            };

        my %options_elements = $obj->options_elements;
        is_deeply(
            \%options_elements, {
                'oink'     => 'blah',
                'xxy'      => 'flop'
            },
            '... got the right hash elements'
        );

        if ( $class->meta->get_attribute('options')->is_lazy ) {
            my $obj = $class->new;

            $obj->set_option( y => 2 );

            is_deeply(
                $obj->options, { x => 1, y => 2 },
                'set_option with lazy default'
            );

            $obj->_clear_options;

            ok(
                $obj->has_option('x'),
                'key for x exists - lazy default'
            );

            $obj->_clear_options;

            ok(
                $obj->is_defined('x'),
                'key for x is defined - lazy default'
            );

            $obj->_clear_options;

            is_deeply(
                [ $obj->key_value ],
                [ [ x => 1 ] ],
                'kv returns lazy default'
            );

            $obj->_clear_options;

            $obj->option_accessor( y => 2 );

            is_deeply(
                [ sort $obj->keys ],
                [ 'x', 'y' ],
                'accessor triggers lazy default generator'
            );
        }
    }
    $class;
}

{
    my ( $class, $handles ) = build_class( isa => 'HashRef' );
    my $obj = $class->new;
    with_immutable {
        is(
            exception { $obj->option_accessor( 'foo', undef ) },
            undef,
            'can use accessor to set value to undef'
        );
        is(
            exception { $obj->quantity(undef) },
            undef,
            'can use accessor to set value to undef'
        );
    }
    $class;
}

done_testing;
