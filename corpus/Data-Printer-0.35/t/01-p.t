use strict;
use warnings;

use Test::More;
BEGIN {
    $ENV{ANSI_COLORS_DISABLED} = 1;
    delete $ENV{DATAPRINTERRC};
    use File::HomeDir::Test;  # avoid user's .dataprinter
};

use Data::Printer;

my $scalar = 'test';
is( p($scalar), '"test"', 'simple scalar' );

my $scalar_ref = \$scalar;
is( p($scalar_ref), '\\ "test"', 'scalar ref' );

my $refref = \$scalar_ref;
is( p($refref), '\\ \\ "test"', 'reference of reference');

$scalar = "\0";
is( p($scalar), '"\0"', 'handling the null character' );

$scalar = "\0foo\0bar \0 baz\0";
is( p($scalar), '"\0foo\0bar \0 baz\0"', 'handling several null characters' );

$scalar = "\0foo\n\0bar\0 baz\n\0";
is( p($scalar), '"\0foo
\0bar\0 baz
\0"', 'null characters in newlines' );

$scalar = 42;
is( p($scalar), '42', 'simple numeric scalar' );

$scalar = -4.2;
is( p($scalar), '-4.2', 'negative float scalar' );

$scalar = '4.2';
is( p($scalar), '4.2', 'stringified float scalar' );

$scalar = 7;
is( p($scalar_ref), '\\ 7', 'simple numeric ref' );

my @array = ();
is( p(@array), '[]', 'empty array' );

undef @array;
is( p(@array), '[]', 'undefined array' );

@array = (1 .. 3);
is( p(@array),
'[
    [0] 1,
    [1] 2,
    [2] 3
]', 'simple array');

@array = ( 1, $scalar_ref );
is( p(@array),
'[
    [0] 1,
    [1] \\ 7
]', 'simple array with scalar ref');
$scalar = 4.2;

@array = ( 1 .. 11 );
is( p(@array),
'[
    [0]  1,
    [1]  2,
    [2]  3,
    [3]  4,
    [4]  5,
    [5]  6,
    [6]  7,
    [7]  8,
    [8]  9,
    [9]  10,
    [10] 11
]', 'simple array alignment');

$array[2] = [ 'foo', 7 ];
$array[5] = [ -6, [ 64 ], 'one', \$scalar ];
is( p(@array),
'[
    [0]  1,
    [1]  2,
    [2]  [
        [0] "foo",
        [1] 7
    ],
    [3]  4,
    [4]  5,
    [5]  [
        [0] -6,
        [1] [
            [0] 64
        ],
        [2] "one",
        [3] \\ 4.2
    ],
    [6]  7,
    [7]  8,
    [8]  9,
    [9]  10,
    [10] 11
]', 'nested array');

my %hash = ();
is( p(%hash), '{}', 'empty hash');

undef %hash;
is( p(%hash), '{}', 'undefined hash');

# the "%hash = 1" code below is wrong and issues
# an "odd number of elements in hash assignment"
# warning message. But since it's just a warning
# (meaning the code will still run even under strictness)
# we make sure to test everything will be alright.
{
    no warnings 'misc';
    %hash = 1;
}
is( p(%hash),
'{
    1   undef
}', 'evil hash of doom');

%hash = ( foo => 33, bar => 99 );
is( p(%hash),
'{
    bar   99,
    foo   33
}', 'simple hash');

$hash{$scalar} = \$scalar;
$hash{hash} = { 1 => 2, 3 => { 4 => 5 }, 10 => 11 };
$hash{something} = [ 3 .. 5 ];
$hash{zelda} = 'moo';

is( p(%hash),
'{
    4.2         \\ 4.2,
    bar         99,
    foo         33,
    hash        {
        1    2,
        3    {
            4   5
        },
        10   11
    },
    something   [
        [0] 3,
        [1] 4,
        [2] 5
    ],
    zelda       "moo"
}', 'nested hash');

@array = ( { 1 => 2 }, 3, { 4 => 5 } );
is( p(@array),
'[
    [0] {
        1   2
    },
    [1] 3,
    [2] {
        4   5
    }
]', 'array of hashes');

my $array_ref = [ 1..2 ];
@array = ( 7, \$array_ref, 8 );
is( p(@array),
'[
    [0] 7,
    [1] \\ [
        [0] 1,
        [1] 2
    ],
    [2] 8
]', 'reference of an array reference');

my $hash_ref = { c => 3 };
%hash = ( a => 1, b => \$hash_ref, d => 4 );
is( p(%hash),
'{
    a   1,
    b   \\ {
        c   3
    },
    d   4
}', 'reference of a hash reference');

is( p($array_ref),
'\\ [
    [0] 1,
    [1] 2
]', 'simple array ref' );

is( p($hash_ref),
'\\ {
    c   3
}', 'simple hash ref' );

# null tests
$scalar = undef;
$scalar_ref = \$scalar;
is( p($scalar), 'undef', 'null test' );

is( p($scalar_ref), '\\ undef', 'null ref' );

@array = ( undef, undef, [ undef ], undef );
is( p(@array),
'[
    [0] undef,
    [1] undef,
    [2] [
        [0] undef
    ],
    [3] undef
]', 'array with undefs' );

%hash = ( 'undef' => undef, foo => { 'meep' => undef }, zed => 26 );
is( p(%hash),
'{
    foo     {
        meep   undef
    },
    undef   undef,
    zed     26
}', 'hash with undefs' );

my $sub = sub { 0 };
is( p($sub), '\ sub { ... }', 'subref test' );

$array[0] = sub { 1 };
$array[2][1] = sub { 2 };
is( p(@array),
'[
    [0] sub { ... },
    [1] undef,
    [2] [
        [0] undef,
        [1] sub { ... }
    ],
    [3] undef
]', 'array with subrefs' );


$hash{foo}{bar} = sub { 3 };
$hash{'undef'} = sub { 4 };
is( p(%hash),
'{
    foo     {
        bar    sub { ... },
        meep   undef
    },
    undef   sub { ... },
    zed     26
}', 'hash with subrefs' );


my $regex = qr{(?:moo(\d|\s)*[a-z]+(.?))}i;
is( p($regex),
'\\ (?:moo(\d|\s)*[a-z]+(.?))  (modifiers: i)', 'regex with modifiers' );

$regex = qr{(?:moo(\d|\s)*[a-z]+(.?))};
is( p($regex), '\ (?:moo(\d|\s)*[a-z]+(.?))', 'plain regex' );

$regex = qr{
      |
    ^ \s* go \s
}x;
is( p($regex), '\ 
      |
    ^ \s* go \s
  (modifiers: x)', 'creepy regex' );

$array[0] = qr{\d(\W)[\s]*};
$array[2][1] = qr{\d(\W)[\s]*};
is( p(@array),
'[
    [0] \d(\W)[\s]*,
    [1] undef,
    [2] [
        [0] undef,
        [1] \d(\W)[\s]*
    ],
    [3] undef
]', 'array with regex' );

$hash{foo}{bar} = qr{\d(\W)[\s]*};
$hash{'undef'} = qr{\d(\W)[\s]*};
is( p(%hash),
'{
    foo     {
        bar    \d(\W)[\s]*,
        meep   undef
    },
    undef   \d(\W)[\s]*,
    zed     26
}', 'hash with regex' );

$scalar = 3;
$scalar_ref = \$scalar;
my $ref2 = \$scalar;
@array = ($scalar, $scalar_ref, $ref2);
is( p(@array),
'[
    [0] 3,
    [1] \\ 3,
    [2] \\ var[1]
]', 'scalar refs in array' );

@array = ();
$array_ref = [];
$hash_ref = {};
$regex = qr{test};
$scalar = 'foobar';

$array[0] = \@array;         # 'var'
$array[1] = $array_ref;
$array[1][0] = $hash_ref;
$array[1][1] = $array_ref;   # 'var[1]'
$array[1][0]->{foo} = $sub;
$array[1][2] = $regex;
$array[2] = $sub;            # 'var[1][0]{foo}'
$array[3] = $regex;          # 'var[1][2]'
$array[4] = $scalar;
$array[5] = $scalar_ref;
$array[6] = $scalar_ref;
$array[7] = \$scalar;
is( p(@array),
'[
    [0] var,
    [1] [
        [0] {
            foo   sub { ... }
        },
        [1] var[1],
        [2] test
    ],
    [2] var[1][0]{foo},
    [3] var[1][2],
    [4] "foobar",
    [5] \\ "foobar",
    [6] \\ var[5],
    [7] \\ var[5]
]', 'handling repeated and circular references' );


done_testing;
