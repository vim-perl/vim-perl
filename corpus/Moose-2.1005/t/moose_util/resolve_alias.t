#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Moose::Util qw( resolve_metaclass_alias resolve_metatrait_alias );

use lib 't/lib';

# Doing each test twice is intended to make sure that the caching
# doesn't break name resolution. It doesn't actually test that
# anything is cached.
is( resolve_metaclass_alias( 'Attribute', 'Moose::Meta::Attribute::Custom::Foo' ),
    'Moose::Meta::Attribute::Custom::Foo',
    'resolve_metaclass_alias finds Moose::Meta::Attribute::Custom::Foo' );

is( resolve_metaclass_alias( 'Attribute', 'Moose::Meta::Attribute::Custom::Foo' ),
    'Moose::Meta::Attribute::Custom::Foo',
    'resolve_metaclass_alias finds Moose::Meta::Attribute::Custom::Foo second time' );

is( resolve_metaclass_alias( 'Attribute', 'Foo' ),
    'Moose::Meta::Attribute::Custom::Foo',
    'resolve_metaclass_alias finds Moose::Meta::Attribute::Custom::Foo via alias (Foo)' );

is( resolve_metaclass_alias( 'Attribute', 'Foo' ),
    'Moose::Meta::Attribute::Custom::Foo',
    'resolve_metaclass_alias finds Moose::Meta::Attribute::Custom::Foo via alias (Foo) a second time' );

is( resolve_metaclass_alias( 'Attribute', 'Moose::Meta::Attribute::Custom::Bar' ),
    'My::Bar',
    'resolve_metaclass_alias finds Moose::Meta::Attribute::Custom::Bar as My::Bar' );

is( resolve_metaclass_alias( 'Attribute', 'Moose::Meta::Attribute::Custom::Bar' ),
    'My::Bar',
    'resolve_metaclass_alias finds Moose::Meta::Attribute::Custom::Bar as My::Bar a second time' );

is( resolve_metaclass_alias( 'Attribute', 'Bar' ),
    'My::Bar',
    'resolve_metaclass_alias finds Moose::Meta::Attribute::Custom::Bar as My::Bar via alias (Bar)' );

is( resolve_metaclass_alias( 'Attribute', 'Bar' ),
    'My::Bar',
    'resolve_metaclass_alias finds Moose::Meta::Attribute::Custom::Bar as My::Bar via alias (Bar) a second time' );

is( resolve_metatrait_alias( 'Attribute', 'Moose::Meta::Attribute::Custom::Trait::Foo' ),
    'Moose::Meta::Attribute::Custom::Trait::Foo',
    'resolve_metatrait_alias finds Moose::Meta::Attribute::Custom::Trait::Foo' );

is( resolve_metatrait_alias( 'Attribute', 'Moose::Meta::Attribute::Custom::Trait::Foo' ),
    'Moose::Meta::Attribute::Custom::Trait::Foo',
    'resolve_metatrait_alias finds Moose::Meta::Attribute::Custom::Trait::Foo second time' );

is( resolve_metatrait_alias( 'Attribute', 'Foo' ),
    'Moose::Meta::Attribute::Custom::Trait::Foo',
    'resolve_metatrait_alias finds Moose::Meta::Attribute::Custom::Trait::Foo via alias (Foo)' );

is( resolve_metatrait_alias( 'Attribute', 'Foo' ),
    'Moose::Meta::Attribute::Custom::Trait::Foo',
    'resolve_metatrait_alias finds Moose::Meta::Attribute::Custom::Trait::Foo via alias (Foo) a second time' );

is( resolve_metatrait_alias( 'Attribute', 'Moose::Meta::Attribute::Custom::Trait::Bar' ),
    'My::Trait::Bar',
    'resolve_metatrait_alias finds Moose::Meta::Attribute::Custom::Trait::Bar as My::Trait::Bar' );

is( resolve_metatrait_alias( 'Attribute', 'Moose::Meta::Attribute::Custom::Trait::Bar' ),
    'My::Trait::Bar',
    'resolve_metatrait_alias finds Moose::Meta::Attribute::Custom::Trait::Bar as My::Trait::Bar a second time' );

is( resolve_metatrait_alias( 'Attribute', 'Bar' ),
    'My::Trait::Bar',
    'resolve_metatrait_alias finds Moose::Meta::Attribute::Custom::Trait::Bar as My::Trait::Bar via alias (Bar)' );

is( resolve_metatrait_alias( 'Attribute', 'Bar' ),
    'My::Trait::Bar',
    'resolve_metatrait_alias finds Moose::Meta::Attribute::Custom::Trait::Bar as My::Trait::Bar via alias (Bar) a second time' );

done_testing;
