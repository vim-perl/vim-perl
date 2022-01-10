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
        count    => 'count',
        elements => 'elements',
        is_empty => 'is_empty',
        push     => 'push',
        push_curried =>
            [ push => 42, 84 ],
        unshift => 'unshift',
        unshift_curried =>
            [ unshift => 42, 84 ],
        pop           => 'pop',
        shift         => 'shift',
        get           => 'get',
        get_curried   => [ get => 1 ],
        set           => 'set',
        set_curried_1 => [ set => 1 ],
        set_curried_2 => [ set => ( 1, 98 ) ],
        accessor      => 'accessor',
        accessor_curried_1 => [ accessor => 1 ],
        accessor_curried_2 => [ accessor => ( 1, 90 ) ],
        clear          => 'clear',
        delete         => 'delete',
        delete_curried => [ delete => 1 ],
        insert         => 'insert',
        insert_curried => [ insert => ( 1, 101 ) ],
        splice         => 'splice',
        splice_curried_1   => [ splice => 1 ],
        splice_curried_2   => [ splice => 1, 2 ],
        splice_curried_all => [ splice => 1, 2, ( 3, 4, 5 ) ],
        sort          => 'sort',
        sort_curried  => [ sort => ( sub { $_[1] <=> $_[0] } ) ],
        sort_in_place => 'sort_in_place',
        sort_in_place_curried =>
            [ sort_in_place => ( sub { $_[1] <=> $_[0] } ) ],
        map           => 'map',
        map_curried   => [ map => ( sub { $_ + 1 } ) ],
        grep          => 'grep',
        grep_curried  => [ grep => ( sub { $_ < 5 } ) ],
        first         => 'first',
        first_curried => [ first => ( sub { $_ % 2 } ) ],
        first_index   => 'first_index',
        first_index_curried => [ first_index => ( sub { $_ % 2 } ) ],
        join          => 'join',
        join_curried => [ join => '-' ],
        shuffle      => 'shuffle',
        uniq         => 'uniq',
        reduce       => 'reduce',
        reduce_curried => [ reduce => ( sub { $_[0] * $_[1] } ) ],
        natatime       => 'natatime',
        natatime_curried => [ natatime => 2 ],
    );

    my $name = 'Foo1';

    sub build_class {
        my %attr = @_;

        my $class = Moose::Meta::Class->create(
            $name++,
            superclasses => ['Moose::Object'],
        );

        my @traits = 'Array';
        push @traits, 'NoInlineAttribute'
            if delete $attr{no_inline};

        $class->add_attribute(
            _values => (
                traits  => \@traits,
                is      => 'rw',
                isa     => 'ArrayRef[Int]',
                default => sub { [] },
                handles => \%handles,
                clearer => '_clear_values',
                %attr,
            ),
        );

        return ( $class->name, \%handles );
    }
}

{
    package Overloader;

    use overload
        '&{}' => sub { ${ $_[0] } },
        bool  => sub {1};

    sub new {
        bless \$_[1], $_[0];
    }
}

{
    package OverloadStr;
    use overload
        q{""} => sub { ${ $_[0] } },
        fallback => 1;

    sub new {
        my $class = shift;
        my $str   = shift;
        return bless \$str, $class;
    }
}

{
    run_tests(build_class);
    run_tests( build_class( lazy => 1, default => sub { [ 42, 84 ] } ) );
    run_tests( build_class( trigger => sub { } ) );
    run_tests( build_class( no_inline => 1 ) );

    # Will force the inlining code to check the entire arrayref when it is modified.
    subtype 'MyArrayRef', as 'ArrayRef', where { 1 };

    run_tests( build_class( isa => 'MyArrayRef' ) );

    coerce 'MyArrayRef', from 'ArrayRef', via { $_ };

    run_tests( build_class( isa => 'MyArrayRef', coerce => 1 ) );
}

sub run_tests {
    my ( $class, $handles ) = @_;

    can_ok( $class, $_ ) for sort keys %{$handles};

    with_immutable {
        my $obj = $class->new( _values => [ 10, 12, 42 ] );

        is_deeply(
            $obj->_values, [ 10, 12, 42 ],
            'values can be set in constructor'
        );

        ok( !$obj->is_empty, 'values is not empty' );
        is( $obj->count, 3, 'count returns 3' );

        like( exception { $obj->count(22) }, qr/Cannot call count with any arguments/, 'throws an error when passing an argument passed to count' );

        is( exception { $obj->push( 1, 2, 3 ) }, undef, 'pushed three new values and lived' );

        is( exception { $obj->push() }, undef, 'call to push without arguments lives' );

        is( exception {
            is( $obj->unshift( 101, 22 ), 8,
                'unshift returns size of the new array' );
        }, undef, 'unshifted two values and lived' );

        is_deeply(
            $obj->_values, [ 101, 22, 10, 12, 42, 1, 2, 3 ],
            'unshift changed the value of the array in the object'
        );

        is( exception { $obj->unshift() }, undef, 'call to unshift without arguments lives' );

        is( $obj->pop, 3, 'pop returns the last value in the array' );

        is_deeply(
            $obj->_values, [ 101, 22, 10, 12, 42, 1, 2 ],
            'pop changed the value of the array in the object'
        );

        like( exception { $obj->pop(42) }, qr/Cannot call pop with any arguments/, 'call to pop with arguments dies' );

        is( $obj->shift, 101, 'shift returns the first value' );

        like( exception { $obj->shift(42) }, qr/Cannot call shift with any arguments/, 'call to shift with arguments dies' );

        is_deeply(
            $obj->_values, [ 22, 10, 12, 42, 1, 2 ],
            'shift changed the value of the array in the object'
        );

        is_deeply(
            [ $obj->elements ], [ 22, 10, 12, 42, 1, 2 ],
            'call to elements returns values as a list'
        );

        like( exception { $obj->elements(22) }, qr/Cannot call elements with any arguments/, 'throws an error when passing an argument passed to elements' );

        $obj->_values( [ 1, 2, 3 ] );

        is( $obj->get(0),      1, 'get values at index 0' );
        is( $obj->get(1),      2, 'get values at index 1' );
        is( $obj->get(2),      3, 'get values at index 2' );
        is( $obj->get_curried, 2, 'get_curried returns value at index 1' );

        like( exception { $obj->get() }, qr/Cannot call get without at least 1 argument/, 'throws an error when get is called without any arguments' );

        like( exception { $obj->get( {} ) }, qr/The index passed to get must be an integer/, 'throws an error when get is called with an invalid argument' );

        like( exception { $obj->get(2.2) }, qr/The index passed to get must be an integer/, 'throws an error when get is called with an invalid argument' );

        like( exception { $obj->get('foo') }, qr/The index passed to get must be an integer/, 'throws an error when get is called with an invalid argument' );

        like( exception { $obj->get_curried(2) }, qr/Cannot call get with more than 1 argument/, 'throws an error when get_curried is called with an argument' );

        is( exception {
            is( $obj->set( 1, 100 ), 100, 'set returns new value' );
        }, undef, 'set value at index 1 lives' );

        is( $obj->get(1), 100, 'get value at index 1 returns new value' );


        like( exception { $obj->set( 1, 99, 42 ) }, qr/Cannot call set with more than 2 arguments/, 'throws an error when set is called with three arguments' );

        is( exception { $obj->set_curried_1(99) }, undef, 'set_curried_1 lives' );

        is( $obj->get(1), 99, 'get value at index 1 returns new value' );

        like( exception { $obj->set_curried_1( 99, 42 ) }, qr/Cannot call set with more than 2 arguments/, 'throws an error when set_curried_1 is called with two arguments' );

        is( exception { $obj->set_curried_2 }, undef, 'set_curried_2 lives' );

        is( $obj->get(1), 98, 'get value at index 1 returns new value' );

        like( exception { $obj->set_curried_2(42) }, qr/Cannot call set with more than 2 arguments/, 'throws an error when set_curried_2 is called with one argument' );

        is(
            $obj->accessor(1), 98,
            'accessor with one argument returns value at index 1'
        );

        is( exception {
            is( $obj->accessor( 1 => 97 ), 97, 'accessor returns new value' );
        }, undef, 'accessor as writer lives' );

        like(
            exception {
                $obj->accessor;
            },
            qr/Cannot call accessor without at least 1 argument/,
            'throws an error when accessor is called without arguments'
        );

        is(
            $obj->get(1), 97,
            'accessor set value at index 1'
        );

        like( exception { $obj->accessor( 1, 96, 42 ) }, qr/Cannot call accessor with more than 2 arguments/, 'throws an error when accessor is called with three arguments' );

        is(
            $obj->accessor_curried_1, 97,
            'accessor_curried_1 returns expected value when called with no arguments'
        );

        is( exception { $obj->accessor_curried_1(95) }, undef, 'accessor_curried_1 as writer lives' );

        is(
            $obj->get(1), 95,
            'accessor_curried_1 set value at index 1'
        );

        like( exception { $obj->accessor_curried_1( 96, 42 ) }, qr/Cannot call accessor with more than 2 arguments/, 'throws an error when accessor_curried_1 is called with two arguments' );

        is( exception { $obj->accessor_curried_2 }, undef, 'accessor_curried_2 as writer lives' );

        is(
            $obj->get(1), 90,
            'accessor_curried_2 set value at index 1'
        );

        like( exception { $obj->accessor_curried_2(42) }, qr/Cannot call accessor with more than 2 arguments/, 'throws an error when accessor_curried_2 is called with one argument' );

        is( exception { $obj->clear }, undef, 'clear lives' );

        ok( $obj->is_empty, 'values is empty after call to clear' );

        is( exception {
            is( $obj->shift, undef,
                'shift returns undef on an empty array' );
        }, undef, 'shifted from an empty array and lived' );

        $obj->set( 0 => 42 );

        like( exception { $obj->clear(50) }, qr/Cannot call clear with any arguments/, 'throws an error when clear is called with an argument' );

        ok(
            !$obj->is_empty,
            'values is not empty after failed call to clear'
        );

        like( exception { $obj->is_empty(50) }, qr/Cannot call is_empty with any arguments/, 'throws an error when is_empty is called with an argument' );

        $obj->clear;
        is(
            $obj->push( 1, 5, 10, 42 ), 4,
            'pushed 4 elements, got number of elements in the array back'
        );

        is( exception {
            is( $obj->delete(2), 10, 'delete returns deleted value' );
        }, undef, 'delete lives' );

        is_deeply(
            $obj->_values, [ 1, 5, 42 ],
            'delete removed the specified element'
        );

        like( exception { $obj->delete( 2, 3 ) }, qr/Cannot call delete with more than 1 argument/, 'throws an error when delete is called with two arguments' );

        is( exception { $obj->delete_curried }, undef, 'delete_curried lives' );

        is_deeply(
            $obj->_values, [ 1, 42 ],
            'delete removed the specified element'
        );

        like( exception { $obj->delete_curried(2) }, qr/Cannot call delete with more than 1 argument/, 'throws an error when delete_curried is called with one argument' );

        is( exception { $obj->insert( 1, 21 ) }, undef, 'insert lives' );

        is_deeply(
            $obj->_values, [ 1, 21, 42 ],
            'insert added the specified element'
        );

        like( exception { $obj->insert( 1, 22, 44 ) }, qr/Cannot call insert with more than 2 arguments/, 'throws an error when insert is called with three arguments' );

        is( exception {
            is_deeply(
                [ $obj->splice( 1, 0, 2, 3 ) ],
                [],
                'return value of splice is empty list when not removing elements'
            );
        }, undef, 'splice lives' );

        is_deeply(
            $obj->_values, [ 1, 2, 3, 21, 42 ],
            'splice added the specified elements'
        );

        is( exception {
            is_deeply(
                [ $obj->splice( 1, 2, 99 ) ],
                [ 2, 3 ],
                'splice returns list of removed values'
            );
        }, undef, 'splice lives' );

        is_deeply(
            $obj->_values, [ 1, 99, 21, 42 ],
            'splice added the specified elements'
        );

        like( exception { $obj->splice() }, qr/Cannot call splice without at least 1 argument/, 'throws an error when splice is called with no arguments' );

        like( exception { $obj->splice( 1, 'foo', ) }, qr/The length argument passed to splice must be an integer/, 'throws an error when splice is called with an invalid length' );

        is( exception { $obj->splice_curried_1( 2, 101 ) }, undef, 'splice_curried_1 lives' );

        is_deeply(
            $obj->_values, [ 1, 101, 42 ],
            'splice added the specified elements'
        );

        is( exception { $obj->splice_curried_2(102) }, undef, 'splice_curried_2 lives' );

        is_deeply(
            $obj->_values, [ 1, 102 ],
            'splice added the specified elements'
        );

        is( exception { $obj->splice_curried_all }, undef, 'splice_curried_all lives' );

        is_deeply(
            $obj->_values, [ 1, 3, 4, 5 ],
            'splice added the specified elements'
        );

        is_deeply(
            scalar $obj->splice( 1, 2 ),
            4,
            'splice in scalar context returns last element removed'
        );

        is_deeply(
            scalar $obj->splice( 1, 0, 42 ),
            undef,
            'splice in scalar context returns undef when no elements are removed'
        );

        $obj->_values( [ 3, 9, 5, 22, 11 ] );

        is_deeply(
            [ $obj->sort ], [ 11, 22, 3, 5, 9 ],
            'sort returns sorted values'
        );

        is_deeply(
            [ $obj->sort( sub { $_[0] <=> $_[1] } ) ], [ 3, 5, 9, 11, 22 ],
            'sort returns values sorted by provided function'
        );

        like( exception { $obj->sort(1) }, qr/The argument passed to sort must be a code reference/, 'throws an error when passing a non coderef to sort' );

        like( exception {
            $obj->sort( sub { }, 27 );
        }, qr/Cannot call sort with more than 1 argument/, 'throws an error when passing two arguments to sort' );

        $obj->_values( [ 3, 9, 5, 22, 11 ] );

        $obj->sort_in_place;

        is_deeply(
            $obj->_values, [ 11, 22, 3, 5, 9 ],
            'sort_in_place sorts values'
        );

        $obj->sort_in_place( sub { $_[0] <=> $_[1] } );

        is_deeply(
            $obj->_values, [ 3, 5, 9, 11, 22 ],
            'sort_in_place with function sorts values'
        );

        like( exception {
            $obj->sort_in_place( 27 );
        }, qr/The argument passed to sort_in_place must be a code reference/, 'throws an error when passing a non coderef to sort_in_place' );

        like( exception {
            $obj->sort_in_place( sub { }, 27 );
        }, qr/Cannot call sort_in_place with more than 1 argument/, 'throws an error when passing two arguments to sort_in_place' );

        $obj->_values( [ 3, 9, 5, 22, 11 ] );

        $obj->sort_in_place_curried;

        is_deeply(
            $obj->_values, [ 22, 11, 9, 5, 3 ],
            'sort_in_place_curried sorts values'
        );

        like( exception { $obj->sort_in_place_curried(27) }, qr/Cannot call sort_in_place with more than 1 argument/, 'throws an error when passing one argument passed to sort_in_place_curried' );

        $obj->_values( [ 1 .. 5 ] );

        is_deeply(
            [ $obj->map( sub { $_ + 1 } ) ],
            [ 2 .. 6 ],
            'map returns the expected values'
        );

        like( exception { $obj->map }, qr/Cannot call map without at least 1 argument/, 'throws an error when passing no arguments to map' );

        like( exception {
            $obj->map( sub { }, 2 );
        }, qr/Cannot call map with more than 1 argument/, 'throws an error when passing two arguments to map' );

        like( exception { $obj->map( {} ) }, qr/The argument passed to map must be a code reference/, 'throws an error when passing a non coderef to map' );

        $obj->_values( [ 1 .. 5 ] );

        is_deeply(
            [ $obj->map_curried ],
            [ 2 .. 6 ],
            'map_curried returns the expected values'
        );

        like( exception {
            $obj->map_curried( sub { } );
        }, qr/Cannot call map with more than 1 argument/, 'throws an error when passing one argument passed to map_curried' );

        $obj->_values( [ 2 .. 9 ] );

        is_deeply(
            [ $obj->grep( sub { $_ < 5 } ) ],
            [ 2 .. 4 ],
            'grep returns the expected values'
        );

        like( exception { $obj->grep }, qr/Cannot call grep without at least 1 argument/, 'throws an error when passing no arguments to grep' );

        like( exception {
            $obj->grep( sub { }, 2 );
        }, qr/Cannot call grep with more than 1 argument/, 'throws an error when passing two arguments to grep' );

        like( exception { $obj->grep( {} ) }, qr/The argument passed to grep must be a code reference/, 'throws an error when passing a non coderef to grep' );

        my $overloader = Overloader->new( sub { $_ < 5 } );
        is_deeply(
            [ $obj->grep($overloader) ],
            [ 2 .. 4 ],
            'grep works with obj that overload code dereferencing'
        );

        is_deeply(
            [ $obj->grep_curried ],
            [ 2 .. 4 ],
            'grep_curried returns the expected values'
        );

        like( exception {
            $obj->grep_curried( sub { } );
        }, qr/Cannot call grep with more than 1 argument/, 'throws an error when passing one argument passed to grep_curried' );

        $obj->_values( [ 2, 4, 22, 99, 101, 6 ] );

        is(
            $obj->first( sub { $_ % 2 } ),
            99,
            'first returns expected value'
        );

        like( exception { $obj->first }, qr/Cannot call first without at least 1 argument/, 'throws an error when passing no arguments to first' );

        like( exception {
            $obj->first( sub { }, 2 );
        }, qr/Cannot call first with more than 1 argument/, 'throws an error when passing two arguments to first' );

        like( exception { $obj->first( {} ) }, qr/The argument passed to first must be a code reference/, 'throws an error when passing a non coderef to first' );

        is(
            $obj->first_curried,
            99,
            'first_curried returns expected value'
        );

        like( exception {
            $obj->first_curried( sub { } );
        }, qr/Cannot call first with more than 1 argument/, 'throws an error when passing one argument passed to first_curried' );


        is(
            $obj->first_index( sub { $_ % 2 } ),
            3,
            'first_index returns expected value'
        );

        like( exception { $obj->first_index }, qr/Cannot call first_index without at least 1 argument/, 'throws an error when passing no arguments to first_index' );

        like( exception {
            $obj->first_index( sub { }, 2 );
        }, qr/Cannot call first_index with more than 1 argument/, 'throws an error when passing two arguments to first_index' );

        like( exception { $obj->first_index( {} ) }, qr/The argument passed to first_index must be a code reference/, 'throws an error when passing a non coderef to first_index' );

        is(
            $obj->first_index_curried,
            3,
            'first_index_curried returns expected value'
        );

        like( exception {
            $obj->first_index_curried( sub { } );
        }, qr/Cannot call first_index with more than 1 argument/, 'throws an error when passing one argument passed to first_index_curried' );


        $obj->_values( [ 1 .. 4 ] );

        is(
            $obj->join('-'), '1-2-3-4',
            'join returns expected result'
        );

        is(
            $obj->join(q{}), '1234',
            'join returns expected result when joining with empty string'
        );

        is(
            $obj->join( OverloadStr->new(q{}) ), '1234',
            'join returns expected result when joining with empty string'
        );

        like( exception { $obj->join }, qr/Cannot call join without at least 1 argument/, 'throws an error when passing no arguments to join' );

        like( exception { $obj->join( '-', 2 ) }, qr/Cannot call join with more than 1 argument/, 'throws an error when passing two arguments to join' );

        like( exception { $obj->join( {} ) }, qr/The argument passed to join must be a string/, 'throws an error when passing a non string to join' );

        is_deeply(
            [ sort $obj->shuffle ],
            [ 1 .. 4 ],
            'shuffle returns all values (cannot check for a random order)'
        );

        like( exception { $obj->shuffle(2) }, qr/Cannot call shuffle with any arguments/, 'throws an error when passing an argument passed to shuffle' );

        $obj->_values( [ 1 .. 4, 2, 5, 3, 7, 3, 3, 1 ] );

        is_deeply(
            [ $obj->uniq ],
            [ 1 .. 4, 5, 7 ],
            'uniq returns expected values (in original order)'
        );

        like( exception { $obj->uniq(2) }, qr/Cannot call uniq with any arguments/, 'throws an error when passing an argument passed to uniq' );

        $obj->_values( [ 1 .. 5 ] );

        is(
            $obj->reduce( sub { $_[0] * $_[1] } ),
            120,
            'reduce returns expected value'
        );

        like( exception { $obj->reduce }, qr/Cannot call reduce without at least 1 argument/, 'throws an error when passing no arguments to reduce' );

        like( exception {
            $obj->reduce( sub { }, 2 );
        }, qr/Cannot call reduce with more than 1 argument/, 'throws an error when passing two arguments to reduce' );

        like( exception { $obj->reduce( {} ) }, qr/The argument passed to reduce must be a code reference/, 'throws an error when passing a non coderef to reduce' );

        is(
            $obj->reduce_curried,
            120,
            'reduce_curried returns expected value'
        );

        like( exception {
            $obj->reduce_curried( sub { } );
        }, qr/Cannot call reduce with more than 1 argument/, 'throws an error when passing one argument passed to reduce_curried' );

        $obj->_values( [ 1 .. 6 ] );

        my $it = $obj->natatime(2);
        my @nat;
        while ( my @v = $it->() ) {
            push @nat, \@v;
        }

        is_deeply(
            [ [ 1, 2 ], [ 3, 4 ], [ 5, 6 ] ],
            \@nat,
            'natatime returns expected iterator'
        );

        @nat = ();
        $obj->natatime( 2, sub { push @nat, [@_] } );

        is_deeply(
            [ [ 1, 2 ], [ 3, 4 ], [ 5, 6 ] ],
            \@nat,
            'natatime with function returns expected value'
        );

        like( exception { $obj->natatime( {} ) }, qr/The n value passed to natatime must be an integer/, 'throws an error when passing a non integer to natatime' );

        like( exception { $obj->natatime( 2, {} ) }, qr/The second argument passed to natatime must be a code reference/, 'throws an error when passing a non code ref to natatime' );

        $it = $obj->natatime_curried();
        @nat = ();
        while ( my @v = $it->() ) {
            push @nat, \@v;
        }

        is_deeply(
            [ [ 1, 2 ], [ 3, 4 ], [ 5, 6 ] ],
            \@nat,
            'natatime_curried returns expected iterator'
        );

        @nat = ();
        $obj->natatime_curried( sub { push @nat, [@_] } );

        is_deeply(
            [ [ 1, 2 ], [ 3, 4 ], [ 5, 6 ] ],
            \@nat,
            'natatime_curried with function returns expected value'
        );

        like( exception { $obj->natatime_curried( {} ) }, qr/The second argument passed to natatime must be a code reference/, 'throws an error when passing a non code ref to natatime_curried' );

        if ( $class->meta->get_attribute('_values')->is_lazy ) {
            my $obj = $class->new;

            is( $obj->count, 2, 'count is 2 (lazy init)' );

            $obj->_clear_values;

            is_deeply(
                [ $obj->elements ], [ 42, 84 ],
                'elements contains default with lazy init'
            );

            $obj->_clear_values;

            $obj->push(2);

            is_deeply(
                $obj->_values, [ 42, 84, 2 ],
                'push works with lazy init'
            );

            $obj->_clear_values;

            $obj->unshift( 3, 4 );

            is_deeply(
                $obj->_values, [ 3, 4, 42, 84 ],
                'unshift works with lazy init'
            );
        }
    }
    $class;
}

{
    my ( $class, $handles ) = build_class( isa => 'ArrayRef' );
    my $obj = $class->new;
    with_immutable {
        is(
            exception { $obj->accessor( 0, undef ) },
            undef,
            'can use accessor to set value to undef'
        );
        is(
            exception { $obj->accessor_curried_1(undef) },
            undef,
            'can use curried accessor to set value to undef'
        );
    }
    $class;
}

done_testing;
