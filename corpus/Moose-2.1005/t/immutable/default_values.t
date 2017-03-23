#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;

{

    package Foo;
    use Moose;

    has 'foo' => ( is => 'rw', default => q{'} );
    has 'bar' => ( is => 'rw', default => q{\\} );
    has 'baz' => ( is => 'rw', default => q{"} );
    has 'buz' => ( is => 'rw', default => q{"'\\} );
    has 'faz' => ( is => 'rw', default => qq{\0} );

    ::is( ::exception {  __PACKAGE__->meta->make_immutable }, undef, 'no errors making a package immutable when it has default values that could break quoting' );
}

my $foo = Foo->new;
is( $foo->foo, q{'},
    'default value for foo attr' );
is( $foo->bar, q{\\},
    'default value for bar attr' );
is( $foo->baz, q{"},
    'default value for baz attr' );
is( $foo->buz, q{"'\\},
    'default value for buz attr' );
is( $foo->faz, qq{\0},
    'default value for faz attr' );


# Lazy attrs were never broken, but it doesn't hurt to test that they
# won't be broken by any future changes.
# Also make sure that attributes stay lazy even after being immutable

{

    package Bar;
    use Moose;

    has 'foo' => ( is => 'rw', default => q{'}, lazy => 1 );
    has 'bar' => ( is => 'rw', default => q{\\}, lazy => 1 );
    has 'baz' => ( is => 'rw', default => q{"}, lazy => 1 );
    has 'buz' => ( is => 'rw', default => q{"'\\}, lazy => 1 );
    has 'faz' => ( is => 'rw', default => qq{\0}, lazy => 1 );

    {
        my $bar = Bar->new;
        ::ok(!$bar->meta->get_attribute($_)->has_value($bar),
             "Attribute $_ has no value")
            for qw(foo bar baz buz faz);
    }

    ::is( ::exception {  __PACKAGE__->meta->make_immutable }, undef, 'no errors making a package immutable when it has lazy default values that could break quoting' );

    {
        my $bar = Bar->new;
        ::ok(!$bar->meta->get_attribute($_)->has_value($bar),
             "Attribute $_ has no value (immutable)")
            for(qw(foo bar baz buz faz));
    }

}

my $bar = Bar->new;
is( $bar->foo, q{'},
    'default value for foo attr' );
is( $bar->bar, q{\\},
    'default value for bar attr' );
is( $bar->baz, q{"},
    'default value for baz attr' );
is( $bar->buz, q{"'\\},
    'default value for buz attr' );
is( $bar->faz, qq{\0},
    'default value for faz attr' );

done_testing;
