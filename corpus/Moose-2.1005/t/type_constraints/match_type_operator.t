#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;

use Moose::Util::TypeConstraints;

# some simple type dispatching ...

subtype 'Null'
    => as 'ArrayRef'
    => where { scalar @{$_} == 0 };

sub head {
    match_on_type @_ =>
        Null => sub { die "Cannot get the head of Null" },
    ArrayRef => sub { $_->[0] };
}

sub tail {
    match_on_type @_ =>
        Null => sub { die "Cannot get the tail of Null" },
    ArrayRef => sub { [ @{ $_ }[ 1 .. $#{ $_ } ] ] };
}

sub len {
    match_on_type @_ =>
        Null => sub { 0 },
    ArrayRef => sub { len( tail( $_ ) ) + 1 };
}

sub rev {
    match_on_type @_ =>
        Null => sub { [] },
    ArrayRef => sub { [ @{ rev( tail( $_ ) ) }, head( $_ ) ] };
}

is( len( [] ), 0, '... got the right length');
is( len( [ 1 ] ), 1, '... got the right length');
is( len( [ 1 .. 5 ] ), 5, '... got the right length');
is( len( [ 1 .. 50 ] ), 50, '... got the right length');

is_deeply(
    rev( [ 1 .. 5 ] ),
    [ reverse 1 .. 5 ],
    '... got the right reversed value'
);

# break down a Maybe Type ...

sub break_it_down {
    match_on_type shift,
        'Maybe[Str]' => sub {
            match_on_type $_ =>
                'Undef' => sub { 'undef' },
                  'Str' => sub { $_      }
        },
        sub { 'default' }
}


is( break_it_down( 'FOO' ), 'FOO', '... got the right value');
is( break_it_down( [] ), 'default', '... got the right value');
is( break_it_down( undef ), 'undef', '... got the right value');
is( break_it_down(), 'undef', '... got the right value');

# checking against enum types

enum RGB  => qw[ red green blue ];
enum CMYK => qw[ cyan magenta yellow black ];

sub is_acceptable_color {
    match_on_type shift,
        'RGB'  => sub { 'RGB'              },
        'CMYK' => sub { 'CMYK'             },
                  sub { die "bad color $_" };
}

is( is_acceptable_color( 'blue' ), 'RGB', '... got the right value');
is( is_acceptable_color( 'green' ), 'RGB', '... got the right value');
is( is_acceptable_color( 'red' ), 'RGB', '... got the right value');
is( is_acceptable_color( 'cyan' ), 'CMYK', '... got the right value');
is( is_acceptable_color( 'magenta' ), 'CMYK', '... got the right value');
is( is_acceptable_color( 'yellow' ), 'CMYK', '... got the right value');
is( is_acceptable_color( 'black' ), 'CMYK', '... got the right value');

isnt( exception {
    is_acceptable_color( 'orange' )
}, undef, '... got the exception' );

## using it in an OO context

{
    package LinkedList;
    use Moose;
    use Moose::Util::TypeConstraints;

    has 'next' => (
        is        => 'ro',
        isa       => __PACKAGE__,
        lazy      => 1,
        default   => sub { __PACKAGE__->new },
        predicate => 'has_next'
    );

    sub pprint {
        my $list = shift;
        match_on_type $list =>
            subtype(
                 as 'LinkedList',
              where { ! $_->has_next }
                       ) => sub { '[]' },
            'LinkedList' => sub { '[' . $_->next->pprint . ']' };
    }
}

my $l = LinkedList->new;
is($l->pprint, '[]', '... got the right pprint');
$l->next;
is($l->pprint, '[[]]', '... got the right pprint');
$l->next->next;
is($l->pprint, '[[[]]]', '... got the right pprint');
$l->next->next->next;
is($l->pprint, '[[[[]]]]', '... got the right pprint');

# basic data dumper

{
    package Foo;
    use Moose;

    sub to_string { 'Foo()' }
}

use B;

sub ppprint {
    my $x = shift;
    match_on_type $x =>
        HashRef   => sub {
            my $hash = shift;
            '{ ' . (join ", " => map {
                        $_ . ' => ' . ppprint( $hash->{ $_ } )
                    } sort keys %$hash ) . ' }'                         },
        ArrayRef  => sub {
            my $array = shift;
            '[ ' . (join ", " => map { ppprint( $_ ) } @$array ) . ' ]' },
        CodeRef   => sub { 'sub { ... }'                                },
        RegexpRef => sub { 'qr/' . $_ . '/'                             },
        GlobRef   => sub { '*' . B::svref_2object($_)->NAME             },
        Object    => sub { $_->can('to_string') ? $_->to_string : $_    },
        ScalarRef => sub { '\\' . ppprint( ${$_} )                      },
        Num       => sub { $_                                           },
        Str       => sub { '"'. $_ . '"'                                },
        Undef     => sub { 'undef'                                      },
                  => sub { die "I don't know what $_ is"                };
}

# The stringification of qr// has changed in 5.13.5+
my $re_prefix = qr/x/ =~ /\(\?\^/ ? '(?^:' :'(?-xism:';

is(
    ppprint(
        {
            one   => [ 1, 2, "three", 4, "five", \(my $x = "six") ],
            two   => undef,
            three => sub { "OH HAI" },
            four  => qr/.*?/,
            five  => \*ppprint,
            six   => Foo->new,
        }
    ),
    qq~{ five => *ppprint, four => qr/$re_prefix.*?)/, one => [ 1, 2, "three", 4, "five", \\"six" ], six => Foo(), three => sub { ... }, two => undef }~,
    '... got the right pretty printed values'
);

# simple JSON serializer

sub to_json {
    my $x = shift;
    match_on_type $x =>
        HashRef   => sub {
            my $hash = shift;
            '{ ' . (join ", " => map {
                        '"' . $_ . '" : ' . to_json( $hash->{ $_ } )
                    } sort keys %$hash ) . ' }'                         },
        ArrayRef  => sub {
            my $array = shift;
            '[ ' . (join ", " => map { to_json( $_ ) } @$array ) . ' ]' },
        Num       => sub { $_                                           },
        Str       => sub { '"'. $_ . '"'                                },
        Undef     => sub { 'null'                                       },
                  => sub { die "$_ is not acceptable json type"         };
}

is(
    to_json( { one => 1, two => 2 } ),
    '{ "one" : 1, "two" : 2 }',
    '... got our valid JSON'
);

is(
    to_json( {
        one   => [ 1, 2, 3, 4 ],
        two   => undef,
        three => "Hello World"
    } ),
    '{ "one" : [ 1, 2, 3, 4 ], "three" : "Hello World", "two" : null }',
    '... got our valid JSON'
);


# some error cases

sub not_enough_matches {
    my $x = shift;
    match_on_type $x =>
        Undef => sub { 'hello undef world'          },
      CodeRef => sub { $_->('Hello code ref world') };
}

like( exception {
    not_enough_matches( [] )
}, qr/No cases matched for /, '... not enough matches' );

done_testing;
