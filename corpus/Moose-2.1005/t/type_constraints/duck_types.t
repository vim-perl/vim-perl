#!/usr/bin/perl
use strict;
use warnings;

use Test::More;
use Test::Fatal;

{

    package Duck;
    use Moose;

    sub quack { }

}

{

    package Swan;
    use Moose;

    sub honk { }

}

{

    package RubberDuck;
    use Moose;

    sub quack { }

}

{

    package DucktypeTest;
    use Moose;
    use Moose::Util::TypeConstraints;

    duck_type 'DuckType' => qw(quack);
    duck_type 'SwanType' => [qw(honk)];

    has duck => (
        isa        => 'DuckType',
        is => 'ro',
        lazy_build => 1,
    );

    sub _build_duck { Duck->new }

    has swan => (
        isa => duck_type( [qw(honk)] ),
        is => 'ro',
    );

    has other_swan => (
        isa => 'SwanType',
        is => 'ro',
    );

}

# try giving it a duck
is( exception { DucktypeTest->new( duck => Duck->new ) }, undef, 'the Duck lives okay' );

# try giving it a swan which is like a duck, but not close enough
like( exception { DucktypeTest->new( duck => Swan->new ) }, qr/Swan is missing methods 'quack'/, "the Swan doesn't quack" );

# try giving it a rubber RubberDuckey
is( exception { DucktypeTest->new( swan => Swan->new ) }, undef, 'but a Swan can honk' );

# try giving it a rubber RubberDuckey
is( exception { DucktypeTest->new( duck => RubberDuck->new ) }, undef, 'the RubberDuck lives okay' );

# try with the other constraint form
is( exception { DucktypeTest->new( other_swan => Swan->new ) }, undef, 'but a Swan can honk' );

my $re = qr/Validation failed for 'DuckType' with value/;

like( exception { DucktypeTest->new( duck => undef ) }, $re, 'Exception for undef' );
like( exception { DucktypeTest->new( duck => [] ) }, $re, 'Exception for arrayref' );
like( exception { DucktypeTest->new( duck => {} ) }, $re, 'Exception for hashref' );
like( exception { DucktypeTest->new( duck => \'foo' ) }, $re, 'Exception for scalar ref' );

done_testing;
