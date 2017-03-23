#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;


{

    package Dog;
    use Moose;

    sub bark_once {
        my $self = shift;
        return 'bark';
    }

    sub bark_twice {
        return 'barkbark';
    }

    around qr/bark.*/ => sub {
        'Dog::around(' . $_[0]->() . ')';
    };

}

my $dog = Dog->new;
is( $dog->bark_once,  'Dog::around(bark)', 'around modifier is called' );
is( $dog->bark_twice, 'Dog::around(barkbark)', 'around modifier is called' );

{

    package Cat;
    use Moose;
    our $BEFORE_BARK_COUNTER = 0;
    our $AFTER_BARK_COUNTER  = 0;

    sub bark_once {
        my $self = shift;
        return 'bark';
    }

    sub bark_twice {
        return 'barkbark';
    }

    before qr/bark.*/ => sub {
        $BEFORE_BARK_COUNTER++;
    };

    after qr/bark.*/ => sub {
        $AFTER_BARK_COUNTER++;
    };

}

my $cat = Cat->new;
$cat->bark_once;
is( $Cat::BEFORE_BARK_COUNTER, 1, 'before modifier is called once' );
is( $Cat::AFTER_BARK_COUNTER,  1, 'after modifier is called once' );
$cat->bark_twice;
is( $Cat::BEFORE_BARK_COUNTER, 2, 'before modifier is called twice' );
is( $Cat::AFTER_BARK_COUNTER,  2, 'after modifier is called twice' );

{
    package Dog::Role;
    use Moose::Role;

    ::isnt( ::exception {
        before qr/bark.*/ => sub {};
    }, undef, '... this is not currently supported' );

    ::isnt( ::exception {
        around qr/bark.*/ => sub {};
    }, undef, '... this is not currently supported' );

    ::isnt( ::exception {
        after  qr/bark.*/ => sub {};
    }, undef, '... this is not currently supported' );

}

done_testing;
