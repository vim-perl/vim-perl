#!/usr/bin/perl

use strict;
use warnings;

use lib 't/lib';

use Moose ();
use Moose::Util::TypeConstraints;
use NoInlineAttribute;
use Test::More;
use Test::Fatal;
use Test::Moose;

{
    my %handles = (
        inc             => 'inc',
        append          => 'append',
        append_curried  => [ append => '!' ],
        prepend         => 'prepend',
        prepend_curried => [ prepend => '-' ],
        replace         => 'replace',
        replace_curried => [ replace => qr/(.)$/, sub { uc $1 } ],
        chop            => 'chop',
        chomp           => 'chomp',
        clear           => 'clear',
        match           => 'match',
        match_curried    => [ match  => qr/\D/ ],
        length           => 'length',
        substr           => 'substr',
        substr_curried_1 => [ substr => (1) ],
        substr_curried_2 => [ substr => ( 1, 3 ) ],
        substr_curried_3 => [ substr => ( 1, 3, 'ong' ) ],
    );

    my $name = 'Foo1';

    sub build_class {
        my %attr = @_;

        my $class = Moose::Meta::Class->create(
            $name++,
            superclasses => ['Moose::Object'],
        );

        my @traits = 'String';
        push @traits, 'NoInlineAttribute'
            if delete $attr{no_inline};

        $class->add_attribute(
            _string => (
                traits  => \@traits,
                is      => 'rw',
                isa     => 'Str',
                default => q{},
                handles => \%handles,
                clearer => '_clear_string',
                %attr,
            ),
        );

        return ( $class->name, \%handles );
    }
}

{
    run_tests(build_class);
    run_tests( build_class( lazy => 1, default => q{} ) );
    run_tests( build_class( trigger => sub { } ) );
    run_tests( build_class( no_inline => 1 ) );

    # Will force the inlining code to check the entire hashref when it is modified.
    subtype 'MyStr', as 'Str', where { 1 };

    run_tests( build_class( isa => 'MyStr' ) );

    coerce 'MyStr', from 'Str', via { $_ };

    run_tests( build_class( isa => 'MyStr', coerce => 1 ) );
}

sub run_tests {
    my ( $class, $handles ) = @_;

    can_ok( $class, $_ ) for sort keys %{$handles};

    with_immutable {
        my $obj = $class->new();

        is( $obj->length, 0, 'length returns zero' );

        $obj->_string('a');
        is( $obj->length, 1, 'length returns 1 for new string' );

        like( exception { $obj->length(42) }, qr/Cannot call length with any arguments/, 'length throws an error when an argument is passed' );

        is( $obj->inc, 'b', 'inc returns new value' );
        is( $obj->_string, 'b', 'a becomes b after inc' );

        like( exception { $obj->inc(42) }, qr/Cannot call inc with any arguments/, 'inc throws an error when an argument is passed' );

        is( $obj->append('foo'), 'bfoo', 'append returns new value' );
        is( $obj->_string, 'bfoo', 'appended to the string' );

        like( exception { $obj->append( 'foo', 2 ) }, qr/Cannot call append with more than 1 argument/, 'append throws an error when two arguments are passed' );

        $obj->append_curried;
        is( $obj->_string, 'bfoo!', 'append_curried appended to the string' );

        like( exception { $obj->append_curried('foo') }, qr/Cannot call append with more than 1 argument/, 'append_curried throws an error when two arguments are passed' );

        $obj->_string("has nl$/");
        is( $obj->chomp, 1, 'chomp returns number of characters removed' );
        is( $obj->_string, 'has nl', 'chomped string' );

        is( $obj->chomp, 0, 'chomp returns number of characters removed' );
        is(
            $obj->_string, 'has nl',
            'chomp is a no-op when string has no line ending'
        );

        like( exception { $obj->chomp(42) }, qr/Cannot call chomp with any arguments/, 'chomp throws an error when an argument is passed' );

        is( $obj->chop, 'l', 'chop returns character removed' );
        is( $obj->_string, 'has n', 'chopped string' );

        like( exception { $obj->chop(42) }, qr/Cannot call chop with any arguments/, 'chop throws an error when an argument is passed' );

        $obj->_string('x');
        is( $obj->prepend('bar'), 'barx', 'prepend returns new value' );
        is( $obj->_string, 'barx', 'prepended to string' );

        $obj->prepend_curried;
        is( $obj->_string, '-barx', 'prepend_curried prepended to string' );

        is(
            $obj->replace( qr/([ao])/, sub { uc($1) } ),
            '-bArx',
            'replace returns new value'
        );

        is(
            $obj->_string, '-bArx',
            'substitution using coderef for replacement'
        );

        $obj->replace( qr/A/, 'X' );
        is(
            $obj->_string, '-bXrx',
            'substitution using string as replacement'
        );

        $obj->_string('foo');
        $obj->replace( qr/oo/, q{} );

        is( $obj->_string, 'f',
            'replace accepts an empty string as second argument' );

        $obj->replace( q{}, 'a' );

        is( $obj->_string, 'af',
            'replace accepts an empty string as first argument' );

        like( exception { $obj->replace( {}, 'x' ) }, qr/The first argument passed to replace must be a string or regexp reference/, 'replace throws an error when the first argument is not a string or regexp' );

        like( exception { $obj->replace( qr/x/, {} ) }, qr/The second argument passed to replace must be a string or code reference/, 'replace throws an error when the first argument is not a string or regexp' );

        $obj->_string('Moosex');
        $obj->replace_curried;
        is( $obj->_string, 'MooseX', 'capitalize last' );

        $obj->_string('abcdef');

        is_deeply(
            [ $obj->match(qr/([az]).*([fy])/) ], [ 'a', 'f' ],
            'match -barx against /[aq]/ returns matches'
        );

        is_deeply(
            [ $obj->match(qr/([az]).*([fy])/) ], [ 'a', 'f' ],
            'match -barx against /[aq]/ returns matches'
        );

        ok(
            scalar $obj->match('b'),
            'match with string as argument returns true'
        );

        ok(
            scalar $obj->match(q{}),
            'match with empty string as argument returns true'
        );

        like( exception { $obj->match }, qr/Cannot call match without at least 1 argument/, 'match throws an error when no arguments are passed' );

        like( exception { $obj->match( {} ) }, qr/The argument passed to match must be a string or regexp reference/, 'match throws an error when an invalid argument is passed' );

        $obj->_string('1234');
        ok( !$obj->match_curried, 'match_curried returns false' );

        $obj->_string('one two three four');
        ok( $obj->match_curried, 'match curried returns true' );

        $obj->clear;
        is( $obj->_string, q{}, 'clear' );

        like( exception { $obj->clear(42) }, qr/Cannot call clear with any arguments/, 'clear throws an error when an argument is passed' );

        $obj->_string('some long string');
        is(
            $obj->substr(1), 'ome long string',
            'substr as getter with one argument'
        );

        $obj->_string('some long string');
        is(
            $obj->substr( 1, 3 ), 'ome',
            'substr as getter with two arguments'
        );

        is(
            $obj->substr( 1, 3, 'ong' ),
            'ome',
            'substr as setter returns replaced string'
        );

        is(
            $obj->_string, 'song long string',
            'substr as setter with three arguments'
        );

        $obj->substr( 1, 3, '' );

        is(
            $obj->_string, 's long string',
            'substr as setter with three arguments, replacment is empty string'
        );

        like( exception { $obj->substr }, qr/Cannot call substr without at least 1 argument/, 'substr throws an error when no argumemts are passed' );

        like( exception { $obj->substr( 1, 2, 3, 4 ) }, qr/Cannot call substr with more than 3 arguments/, 'substr throws an error when four argumemts are passed' );

        like( exception { $obj->substr( {} ) }, qr/The first argument passed to substr must be an integer/, 'substr throws an error when first argument is not an integer' );

        like( exception { $obj->substr( 1, {} ) }, qr/The second argument passed to substr must be an integer/, 'substr throws an error when second argument is not an integer' );

        like( exception { $obj->substr( 1, 2, {} ) }, qr/The third argument passed to substr must be a string/, 'substr throws an error when third argument is not a string' );

        $obj->_string('some long string');

        is(
            $obj->substr_curried_1, 'ome long string',
            'substr_curried_1 returns expected value'
        );

        is(
            $obj->substr_curried_1(3), 'ome',
            'substr_curried_1 with one argument returns expected value'
        );

        $obj->substr_curried_1( 3, 'ong' );

        is(
            $obj->_string, 'song long string',
            'substr_curried_1 as setter with two arguments'
        );

        $obj->_string('some long string');

        is(
            $obj->substr_curried_2, 'ome',
            'substr_curried_2 returns expected value'
        );

        $obj->substr_curried_2('ong');

        is(
            $obj->_string, 'song long string',
            'substr_curried_2 as setter with one arguments'
        );

        $obj->_string('some long string');

        $obj->substr_curried_3;

        is(
            $obj->_string, 'song long string',
            'substr_curried_3 as setter'
        );

        if ( $class->meta->get_attribute('_string')->is_lazy ) {
            my $obj = $class->new;

            $obj->append('foo');

            is(
                $obj->_string, 'foo',
                'append with lazy default'
            );
        }
    }
    $class;
}

done_testing;
