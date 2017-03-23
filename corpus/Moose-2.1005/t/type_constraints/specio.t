#!/usr/bin/perl

use strict;
use warnings;

# Prevent namespace::autoclean from dying when we run tests from git checkout.
use Class::MOP ();
use Moose      ();
BEGIN { $Class::MOP::VERSION ||= $Moose::VERSION ||= 3 }

use Test::Fatal;
use Test::Moose qw( with_immutable );
use Test::More;

use Test::Requires {
    'Specio' => '0.07',
};

{
    package Foo;

    use Moose;
    use Specio::Library::Builtins;

    has int => (
        is  => 'ro',
        isa => t('Int'),
    );

    has array_of_ints => (
        is  => 'ro',
        isa => t( 'ArrayRef', of => t('Int') ),
    );

    has hash_of_ints => (
        is  => 'ro',
        isa => t( 'HashRef', of => t('Int') ),
    );
}

with_immutable(
    sub {
        my $is_immutable = shift;
        subtest(
            'Foo class' . ( $is_immutable ? ' (immutable)' : q{} ),
            sub {

                is(
                    exception { Foo->new( int => 42 ) },
                    undef,
                    '42 is an acceptable int'
                );

                like(
                    exception { Foo->new( int => 42.4 ) },
                    qr/does not pass the type constraint.+for type named Int/,
                    '42.4 is not an acceptable int'
                );

                is(
                    exception { Foo->new( array_of_ints => [ 42, 84 ] ) },
                    undef,
                    '[ 42, 84 ] is an acceptable array of ints'
                );

                like(
                    exception { Foo->new( array_of_ints => [ 42.4, 84 ] ) },
                    qr/does not pass the type constraint.+for anonymous type/,
                    '[ 42.4, 84 ] is an acceptable array of ints'
                );

                is(
                    exception {
                        Foo->new( hash_of_ints => { foo => 42, bar => 84 } );
                    },
                    undef,
                    '{ foo => 42, bar => 84 } is an acceptable array of ints'
                );

                like(
                    exception {
                        Foo->new(
                            hash_of_ints => { foo => 42.4, bar => 84 } );
                    },
                    qr/does not pass the type constraint.+for anonymous type/,
                    '{ foo => 42.4, bar => 84 } is an acceptable array of ints'
                );
            }
        );
    },
    'Foo'
);

{
    package Bar;

    use Moose;
    use Specio::Declare;
    use Specio::Library::Builtins;

    my $array_of_ints = anon( parent => t( 'ArrayRef', of => t('Int') ) );

    coerce(
        $array_of_ints,
        from  => t('Int'),
        using => sub {
            return [ $_[0] ];
        }
    );

    has array_of_ints => (
        is     => 'ro',
        isa    => $array_of_ints,
        coerce => 1,
    );

    my $hash_of_ints = anon( parent => t( 'HashRef', of => t('Int') ) );

    coerce(
        $hash_of_ints,
        from  => t('Int'),
        using => sub {
            return { foo => $_[0] };
        }
    );

    has hash_of_ints => (
        is     => 'ro',
        isa    => $hash_of_ints,
        coerce => 1,
    );
}

with_immutable(
    sub {
        my $is_immutable = shift;
        subtest(
            'Bar class' . ( $is_immutable ? ' (immutable)' : q{} ),
            sub {

                is(
                    exception { Bar->new( array_of_ints => [ 42, 84 ] ) },
                    undef,
                    '[ 42, 84 ] is an acceptable array of ints'
                );

                like(
                    exception { Bar->new( array_of_ints => [ 42.4, 84 ] ) },
                    qr/does not pass the type constraint.+for anonymous type/,
                    '[ 42.4, 84 ] is an acceptable array of ints'
                );

                {
                    my $bar;
                    is(
                        exception { $bar = Bar->new( array_of_ints => 42 ) },
                        undef,
                        '42 is an acceptable array of ints with coercion'
                    );

                    is_deeply(
                        $bar->array_of_ints(),
                        [42],
                        'int is coerced to single element arrayref'
                    );
                }

                is(
                    exception {
                        Bar->new( hash_of_ints => { foo => 42, bar => 84 } );
                    },
                    undef,
                    '{ foo => 42, bar => 84 } is an acceptable array of ints'
                );

                like(
                    exception {
                        Bar->new(
                            hash_of_ints => { foo => 42.4, bar => 84 } );
                    },
                    qr/does not pass the type constraint.+for anonymous type/,
                    '{ foo => 42.4, bar => 84 } is an acceptable array of ints'
                );

                {
                    my $bar;
                    is(
                        exception { $bar = Bar->new( hash_of_ints => 42 ) },
                        undef,
                        '42 is an acceptable hash of ints with coercion'
                    );

                    is_deeply(
                        $bar->hash_of_ints(),
                        { foo => 42 },
                        'int is coerced to single element hashref'
                    );
                }
            }
        );
    },
    'Bar'
);

done_testing();
