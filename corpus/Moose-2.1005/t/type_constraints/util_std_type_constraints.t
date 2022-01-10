#!/usr/bin/perl

use strict;
use warnings;

use Test::Fatal;
use Test::More;

use Eval::Closure;
use IO::File;
use Moose::Util::TypeConstraints;
use Scalar::Util qw( blessed openhandle );

my $ZERO    = 0;
my $ONE     = 1;
my $INT     = 100;
my $NEG_INT = -100;
my $NUM     = 42.42;
my $NEG_NUM = -42.42;

my $EMPTY_STRING  = q{};
my $STRING        = 'foo';
my $NUM_IN_STRING = 'has 42 in it';
my $INT_WITH_NL1  = "1\n";
my $INT_WITH_NL2  = "\n1";

my $SCALAR_REF     = \( my $var );
my $SCALAR_REF_REF = \$SCALAR_REF;
my $ARRAY_REF      = [];
my $HASH_REF       = {};
my $CODE_REF       = sub { };

my $GLOB     = do { no warnings 'once'; *GLOB_REF };
my $GLOB_REF = \$GLOB;

open my $FH, '<', $0 or die "Could not open $0 for the test";

my $FH_OBJECT = IO::File->new( $0, 'r' )
    or die "Could not open $0 for the test";

my $REGEX      = qr/../;
my $REGEX_OBJ  = bless qr/../, 'BlessedQR';
my $FAKE_REGEX = bless {}, 'Regexp';

my $OBJECT = bless {}, 'Foo';

my $UNDEF = undef;

{
    package Thing;

    sub foo { }
}

my $CLASS_NAME = 'Thing';

{
    package Role;
    use Moose::Role;

    sub foo { }
}

my $ROLE_NAME = 'Role';

my %tests = (
    Any => {
        accept => [
            $ZERO,
            $ONE,
            $INT,
            $NEG_INT,
            $NUM,
            $NEG_NUM,
            $EMPTY_STRING,
            $STRING,
            $NUM_IN_STRING,
            $INT_WITH_NL1,
            $INT_WITH_NL2,
            $SCALAR_REF,
            $SCALAR_REF_REF,
            $ARRAY_REF,
            $HASH_REF,
            $CODE_REF,
            $GLOB,
            $GLOB_REF,
            $FH,
            $FH_OBJECT,
            $REGEX,
            $REGEX_OBJ,
            $FAKE_REGEX,
            $OBJECT,
            $UNDEF,
        ],
    },
    Item => {
        accept => [
            $ZERO,
            $ONE,
            $INT,
            $NEG_INT,
            $NUM,
            $NEG_NUM,
            $EMPTY_STRING,
            $STRING,
            $NUM_IN_STRING,
            $INT_WITH_NL1,
            $INT_WITH_NL2,
            $SCALAR_REF,
            $SCALAR_REF_REF,
            $ARRAY_REF,
            $HASH_REF,
            $CODE_REF,
            $GLOB,
            $GLOB_REF,
            $FH,
            $FH_OBJECT,
            $REGEX,
            $REGEX_OBJ,
            $FAKE_REGEX,
            $OBJECT,
            $UNDEF,
        ],
    },
    Defined => {
        accept => [
            $ZERO,
            $ONE,
            $INT,
            $NEG_INT,
            $NUM,
            $NEG_NUM,
            $EMPTY_STRING,
            $STRING,
            $NUM_IN_STRING,
            $INT_WITH_NL1,
            $INT_WITH_NL2,
            $SCALAR_REF,
            $SCALAR_REF_REF,
            $ARRAY_REF,
            $HASH_REF,
            $CODE_REF,
            $GLOB,
            $GLOB_REF,
            $FH,
            $FH_OBJECT,
            $REGEX,
            $REGEX_OBJ,
            $FAKE_REGEX,
            $OBJECT,
        ],
        reject => [
            $UNDEF,
        ],
    },
    Undef => {
        accept => [
            $UNDEF,
        ],
        reject => [
            $ZERO,
            $ONE,
            $INT,
            $NEG_INT,
            $NUM,
            $NEG_NUM,
            $EMPTY_STRING,
            $STRING,
            $NUM_IN_STRING,
            $INT_WITH_NL1,
            $INT_WITH_NL2,
            $SCALAR_REF,
            $SCALAR_REF_REF,
            $ARRAY_REF,
            $HASH_REF,
            $CODE_REF,
            $GLOB,
            $GLOB_REF,
            $FH,
            $FH_OBJECT,
            $REGEX,
            $REGEX_OBJ,
            $FAKE_REGEX,
            $OBJECT,
        ],
    },
    Bool => {
        accept => [
            $ZERO,
            $ONE,
            $EMPTY_STRING,
            $UNDEF,
        ],
        reject => [
            $INT,
            $NEG_INT,
            $NUM,
            $NEG_NUM,
            $STRING,
            $NUM_IN_STRING,
            $INT_WITH_NL1,
            $INT_WITH_NL2,
            $SCALAR_REF,
            $SCALAR_REF_REF,
            $ARRAY_REF,
            $HASH_REF,
            $CODE_REF,
            $GLOB,
            $GLOB_REF,
            $FH,
            $FH_OBJECT,
            $REGEX,
            $REGEX_OBJ,
            $FAKE_REGEX,
            $OBJECT,
        ],
    },
    Maybe => {
        accept => [
            $ZERO,
            $ONE,
            $INT,
            $NEG_INT,
            $NUM,
            $NEG_NUM,
            $EMPTY_STRING,
            $STRING,
            $NUM_IN_STRING,
            $INT_WITH_NL1,
            $INT_WITH_NL2,
            $SCALAR_REF,
            $SCALAR_REF_REF,
            $ARRAY_REF,
            $HASH_REF,
            $CODE_REF,
            $GLOB,
            $GLOB_REF,
            $FH,
            $FH_OBJECT,
            $REGEX,
            $REGEX_OBJ,
            $FAKE_REGEX,
            $OBJECT,
            $UNDEF,
        ],
    },
    Value => {
        accept => [
            $ZERO,
            $ONE,
            $INT,
            $NEG_INT,
            $NUM,
            $NEG_NUM,
            $EMPTY_STRING,
            $STRING,
            $NUM_IN_STRING,
            $INT_WITH_NL1,
            $INT_WITH_NL2,
            $GLOB,
        ],
        reject => [
            $SCALAR_REF,
            $SCALAR_REF_REF,
            $ARRAY_REF,
            $HASH_REF,
            $CODE_REF,
            $GLOB_REF,
            $FH,
            $FH_OBJECT,
            $REGEX,
            $REGEX_OBJ,
            $FAKE_REGEX,
            $OBJECT,
            $UNDEF,
        ],
    },
    Ref => {
        accept => [
            $SCALAR_REF,
            $SCALAR_REF_REF,
            $ARRAY_REF,
            $HASH_REF,
            $CODE_REF,
            $GLOB_REF,
            $FH,
            $FH_OBJECT,
            $REGEX,
            $REGEX_OBJ,
            $FAKE_REGEX,
            $OBJECT,
        ],
        reject => [
            $ZERO,
            $ONE,
            $INT,
            $NEG_INT,
            $NUM,
            $NEG_NUM,
            $EMPTY_STRING,
            $STRING,
            $NUM_IN_STRING,
            $INT_WITH_NL1,
            $INT_WITH_NL2,
            $GLOB,
            $UNDEF,
        ],
    },
    Num => {
        accept => [
            $ZERO,
            $ONE,
            $INT,
            $NEG_INT,
            $NUM,
            $NEG_NUM,
        ],
        reject => [
            $EMPTY_STRING,
            $STRING,
            $NUM_IN_STRING,
            $SCALAR_REF,
            $SCALAR_REF_REF,
            $ARRAY_REF,
            $HASH_REF,
            $CODE_REF,
            $GLOB,
            $GLOB_REF,
            $FH,
            $FH_OBJECT,
            $REGEX,
            $REGEX_OBJ,
            $FAKE_REGEX,
            $OBJECT,
            $UNDEF,
            $INT_WITH_NL1,
            $INT_WITH_NL2,
        ],
    },
    Int => {
        accept => [
            $ZERO,
            $ONE,
            $INT,
            $NEG_INT,
        ],
        reject => [
            $NUM,
            $NEG_NUM,
            $EMPTY_STRING,
            $STRING,
            $NUM_IN_STRING,
            $INT_WITH_NL1,
            $INT_WITH_NL2,
            $SCALAR_REF,
            $SCALAR_REF_REF,
            $ARRAY_REF,
            $HASH_REF,
            $CODE_REF,
            $GLOB,
            $GLOB_REF,
            $FH,
            $FH_OBJECT,
            $REGEX,
            $REGEX_OBJ,
            $FAKE_REGEX,
            $OBJECT,
            $UNDEF,
        ],
    },
    Str => {
        accept => [
            $ZERO,
            $ONE,
            $INT,
            $NEG_INT,
            $NUM,
            $NEG_NUM,
            $EMPTY_STRING,
            $STRING,
            $NUM_IN_STRING,
            $INT_WITH_NL1,
            $INT_WITH_NL2,
        ],
        reject => [
            $SCALAR_REF,
            $SCALAR_REF_REF,
            $ARRAY_REF,
            $HASH_REF,
            $CODE_REF,
            $GLOB,
            $GLOB_REF,
            $FH,
            $FH_OBJECT,
            $REGEX,
            $REGEX_OBJ,
            $FAKE_REGEX,
            $OBJECT,
            $UNDEF,
        ],
    },
    ScalarRef => {
        accept => [
            $SCALAR_REF,
            $SCALAR_REF_REF,
        ],
        reject => [
            $ZERO,
            $ONE,
            $INT,
            $NEG_INT,
            $NUM,
            $NEG_NUM,
            $EMPTY_STRING,
            $STRING,
            $NUM_IN_STRING,
            $INT_WITH_NL1,
            $INT_WITH_NL2,
            $ARRAY_REF,
            $HASH_REF,
            $CODE_REF,
            $GLOB,
            $GLOB_REF,
            $FH,
            $FH_OBJECT,
            $REGEX,
            $REGEX_OBJ,
            $FAKE_REGEX,
            $OBJECT,
            $UNDEF,
        ],
    },
    ArrayRef => {
        accept => [
            $ARRAY_REF,
        ],
        reject => [
            $ZERO,
            $ONE,
            $INT,
            $NEG_INT,
            $NUM,
            $NEG_NUM,
            $EMPTY_STRING,
            $STRING,
            $NUM_IN_STRING,
            $INT_WITH_NL1,
            $INT_WITH_NL2,
            $SCALAR_REF,
            $SCALAR_REF_REF,
            $HASH_REF,
            $CODE_REF,
            $GLOB,
            $GLOB_REF,
            $FH,
            $FH_OBJECT,
            $REGEX,
            $REGEX_OBJ,
            $FAKE_REGEX,
            $OBJECT,
            $UNDEF,
        ],
    },
    HashRef => {
        accept => [
            $HASH_REF,
        ],
        reject => [
            $ZERO,
            $ONE,
            $INT,
            $NEG_INT,
            $NUM,
            $NEG_NUM,
            $EMPTY_STRING,
            $STRING,
            $NUM_IN_STRING,
            $INT_WITH_NL1,
            $INT_WITH_NL2,
            $SCALAR_REF,
            $SCALAR_REF_REF,
            $ARRAY_REF,
            $CODE_REF,
            $GLOB,
            $GLOB_REF,
            $FH,
            $FH_OBJECT,
            $REGEX,
            $REGEX_OBJ,
            $FAKE_REGEX,
            $OBJECT,
            $UNDEF,
        ],
    },
    CodeRef => {
        accept => [
            $CODE_REF,
        ],
        reject => [
            $ZERO,
            $ONE,
            $INT,
            $NEG_INT,
            $NUM,
            $NEG_NUM,
            $EMPTY_STRING,
            $STRING,
            $NUM_IN_STRING,
            $INT_WITH_NL1,
            $INT_WITH_NL2,
            $SCALAR_REF,
            $SCALAR_REF_REF,
            $ARRAY_REF,
            $HASH_REF,
            $GLOB,
            $GLOB_REF,
            $FH,
            $FH_OBJECT,
            $REGEX,
            $REGEX_OBJ,
            $FAKE_REGEX,
            $OBJECT,
            $UNDEF,
        ],
    },
    RegexpRef => {
        accept => [
            $REGEX,
            $REGEX_OBJ,
        ],
        reject => [
            $ZERO,
            $ONE,
            $INT,
            $NEG_INT,
            $NUM,
            $NEG_NUM,
            $EMPTY_STRING,
            $STRING,
            $NUM_IN_STRING,
            $INT_WITH_NL1,
            $INT_WITH_NL2,
            $SCALAR_REF,
            $SCALAR_REF_REF,
            $ARRAY_REF,
            $HASH_REF,
            $CODE_REF,
            $GLOB,
            $GLOB_REF,
            $FH,
            $FH_OBJECT,
            $OBJECT,
            $UNDEF,
            $FAKE_REGEX,
        ],
    },
    GlobRef => {
        accept => [
            $GLOB_REF,
            $FH,
        ],
        reject => [
            $ZERO,
            $ONE,
            $INT,
            $NEG_INT,
            $NUM,
            $NEG_NUM,
            $EMPTY_STRING,
            $STRING,
            $NUM_IN_STRING,
            $INT_WITH_NL1,
            $INT_WITH_NL2,
            $SCALAR_REF,
            $SCALAR_REF_REF,
            $ARRAY_REF,
            $HASH_REF,
            $CODE_REF,
            $GLOB,
            $FH_OBJECT,
            $OBJECT,
            $REGEX,
            $REGEX_OBJ,
            $FAKE_REGEX,
            $UNDEF,
        ],
    },
    FileHandle => {
        accept => [
            $FH,
            $FH_OBJECT,
        ],
        reject => [
            $ZERO,
            $ONE,
            $INT,
            $NEG_INT,
            $NUM,
            $NEG_NUM,
            $EMPTY_STRING,
            $STRING,
            $NUM_IN_STRING,
            $INT_WITH_NL1,
            $INT_WITH_NL2,
            $SCALAR_REF,
            $SCALAR_REF_REF,
            $ARRAY_REF,
            $HASH_REF,
            $CODE_REF,
            $GLOB,
            $GLOB_REF,
            $OBJECT,
            $REGEX,
            $REGEX_OBJ,
            $FAKE_REGEX,
            $UNDEF,
        ],
    },
    Object => {
        accept => [
            $FH_OBJECT,
            $REGEX,
            $REGEX_OBJ,
            $FAKE_REGEX,
            $OBJECT,
        ],
        reject => [
            $ZERO,
            $ONE,
            $INT,
            $NEG_INT,
            $NUM,
            $NEG_NUM,
            $EMPTY_STRING,
            $STRING,
            $NUM_IN_STRING,
            $INT_WITH_NL1,
            $INT_WITH_NL2,
            $SCALAR_REF,
            $SCALAR_REF_REF,
            $ARRAY_REF,
            $HASH_REF,
            $CODE_REF,
            $GLOB,
            $GLOB_REF,
            $FH,
            $UNDEF,
        ],
    },
    ClassName => {
        accept => [
            $CLASS_NAME,
            $ROLE_NAME,
        ],
        reject => [
            $ZERO,
            $ONE,
            $INT,
            $NEG_INT,
            $NUM,
            $NEG_NUM,
            $EMPTY_STRING,
            $STRING,
            $NUM_IN_STRING,
            $INT_WITH_NL1,
            $INT_WITH_NL2,
            $SCALAR_REF,
            $SCALAR_REF_REF,
            $ARRAY_REF,
            $HASH_REF,
            $CODE_REF,
            $GLOB,
            $GLOB_REF,
            $FH,
            $FH_OBJECT,
            $REGEX,
            $REGEX_OBJ,
            $FAKE_REGEX,
            $OBJECT,
            $UNDEF,
        ],
    },
    RoleName => {
        accept => [
            $ROLE_NAME,
        ],
        reject => [
            $CLASS_NAME,
            $ZERO,
            $ONE,
            $INT,
            $NEG_INT,
            $NUM,
            $NEG_NUM,
            $EMPTY_STRING,
            $STRING,
            $NUM_IN_STRING,
            $INT_WITH_NL1,
            $INT_WITH_NL2,
            $SCALAR_REF,
            $SCALAR_REF_REF,
            $ARRAY_REF,
            $HASH_REF,
            $CODE_REF,
            $GLOB,
            $GLOB_REF,
            $FH,
            $FH_OBJECT,
            $REGEX,
            $REGEX_OBJ,
            $FAKE_REGEX,
            $OBJECT,
            $UNDEF,
        ],
    },
);

for my $name ( sort keys %tests ) {
    test_constraint( $name, $tests{$name} );

    test_constraint(
        Moose::Util::TypeConstraints::find_or_create_type_constraint(
            "$name|$name"),
        $tests{$name}
    );
}

my %substr_test_str = (
    ClassName   => 'x' . $CLASS_NAME,
    RoleName    => 'x' . $ROLE_NAME,
);

# We need to test that the Str constraint (and types that derive from it)
# accept the return val of substr() - which means passing that return val
# directly to the checking code
foreach my $type_name (qw(Str Num Int ClassName RoleName))
{
    my $str = $substr_test_str{$type_name} || '123456789';

    my $type = Moose::Util::TypeConstraints::find_type_constraint($type_name);

    my $unoptimized
        = $type->has_parent
        ? $type->_compile_subtype( $type->constraint )
        : $type->_compile_type( $type->constraint );

    my $inlined;
    {
        $inlined = eval_closure(
            source => 'sub { ( ' . $type->_inline_check('$_[0]') . ' ) }',
        );
    }

    ok(
        $type->check( substr( $str, 1, 5 ) ),
        $type_name . ' accepts return val from substr using ->check'
    );
    ok(
        $unoptimized->( substr( $str, 1, 5 ) ),
        $type_name . ' accepts return val from substr using unoptimized constraint'
    );
    ok(
        $inlined->( substr( $str, 1, 5 ) ),
        $type_name . ' accepts return val from substr using inlined constraint'
    );

    # only Str accepts empty strings.
    next unless $type_name eq 'Str';

    ok(
        $type->check( substr( $str, 0, 0 ) ),
        $type_name . ' accepts empty return val from substr using ->check'
    );
    ok(
        $unoptimized->( substr( $str, 0, 0 ) ),
        $type_name . ' accepts empty return val from substr using unoptimized constraint'
    );
    ok(
        $inlined->( substr( $str, 0, 0 ) ),
        $type_name . ' accepts empty return val from substr using inlined constraint'
    );
}

{
    my $class_tc = class_type('Thing');

    test_constraint(
        $class_tc, {
            accept => [
                ( bless {}, 'Thing' ),
            ],
            reject => [
                'Thing',
                $ZERO,
                $ONE,
                $INT,
                $NEG_INT,
                $NUM,
                $NEG_NUM,
                $EMPTY_STRING,
                $STRING,
                $NUM_IN_STRING,
                $INT_WITH_NL1,
                $INT_WITH_NL2,
                $SCALAR_REF,
                $SCALAR_REF_REF,
                $ARRAY_REF,
                $HASH_REF,
                $CODE_REF,
                $GLOB,
                $GLOB_REF,
                $FH,
                $FH_OBJECT,
                $REGEX,
                $REGEX_OBJ,
                $FAKE_REGEX,
                $OBJECT,
                $UNDEF,
            ],
        }
    );
}

{
    package Duck;

    sub quack { }
    sub flap  { }
}

{
    package DuckLike;

    sub quack { }
    sub flap  { }
}

{
    package Bird;

    sub flap { }
}

{
    my @methods = qw( quack flap );
    duck_type 'Duck' => @methods;

    test_constraint(
        'Duck', {
            accept => [
                ( bless {}, 'Duck' ),
                ( bless {}, 'DuckLike' ),
            ],
            reject => [
                $ZERO,
                $ONE,
                $INT,
                $NEG_INT,
                $NUM,
                $NEG_NUM,
                $EMPTY_STRING,
                $STRING,
                $NUM_IN_STRING,
                $INT_WITH_NL1,
                $INT_WITH_NL2,
                $SCALAR_REF,
                $SCALAR_REF_REF,
                $ARRAY_REF,
                $HASH_REF,
                $CODE_REF,
                $GLOB,
                $GLOB_REF,
                $FH,
                $FH_OBJECT,
                $REGEX,
                $REGEX_OBJ,
                $FAKE_REGEX,
                $OBJECT,
                ( bless {}, 'Bird' ),
                $UNDEF,
            ],
        }
    );
}

{
    my @allowed = qw( bar baz quux );
    enum 'Enumerated' => @allowed;

    test_constraint(
        'Enumerated', {
            accept => \@allowed,
            reject => [
                $ZERO,
                $ONE,
                $INT,
                $NEG_INT,
                $NUM,
                $NEG_NUM,
                $EMPTY_STRING,
                $STRING,
                $NUM_IN_STRING,
                $INT_WITH_NL1,
                $INT_WITH_NL2,
                $SCALAR_REF,
                $SCALAR_REF_REF,
                $ARRAY_REF,
                $HASH_REF,
                $CODE_REF,
                $GLOB,
                $GLOB_REF,
                $FH,
                $FH_OBJECT,
                $REGEX,
                $REGEX_OBJ,
                $FAKE_REGEX,
                $OBJECT,
                $UNDEF,
            ],
        }
    );
}

{
    my $union = Moose::Meta::TypeConstraint::Union->new(
        type_constraints => [
            find_type_constraint('Int'),
            find_type_constraint('Object'),
        ],
    );

    test_constraint(
        $union, {
            accept => [
                $ZERO,
                $ONE,
                $INT,
                $NEG_INT,
                $FH_OBJECT,
                $REGEX,
                $REGEX_OBJ,
                $FAKE_REGEX,
                $OBJECT,
            ],
            reject => [
                $NUM,
                $NEG_NUM,
                $EMPTY_STRING,
                $STRING,
                $NUM_IN_STRING,
                $INT_WITH_NL1,
                $INT_WITH_NL2,
                $SCALAR_REF,
                $SCALAR_REF_REF,
                $ARRAY_REF,
                $HASH_REF,
                $CODE_REF,
                $GLOB,
                $GLOB_REF,
                $FH,
                $UNDEF,
            ],
        }
    );
}
{
    note 'Anonymous Union Test';

    my $union = union(['Int','Object']);

    test_constraint(
        $union, {
            accept => [
                $ZERO,
                $ONE,
                $INT,
                $NEG_INT,
                $FH_OBJECT,
                $REGEX,
                $REGEX_OBJ,
                $FAKE_REGEX,
                $OBJECT,
            ],
            reject => [
                $NUM,
                $NEG_NUM,
                $EMPTY_STRING,
                $STRING,
                $NUM_IN_STRING,
                $INT_WITH_NL1,
                $INT_WITH_NL2,
                $SCALAR_REF,
                $SCALAR_REF_REF,
                $ARRAY_REF,
                $HASH_REF,
                $CODE_REF,
                $GLOB,
                $GLOB_REF,
                $FH,
                $UNDEF,
            ],
        }
    );
}
{
    note 'Named Union Test';
    union 'NamedUnion' => ['Int','Object'];

    test_constraint(
        'NamedUnion', {
            accept => [
                $ZERO,
                $ONE,
                $INT,
                $NEG_INT,
                $FH_OBJECT,
                $REGEX,
                $REGEX_OBJ,
                $FAKE_REGEX,
                $OBJECT,
            ],
            reject => [
                $NUM,
                $NEG_NUM,
                $EMPTY_STRING,
                $STRING,
                $NUM_IN_STRING,
                $INT_WITH_NL1,
                $INT_WITH_NL2,
                $SCALAR_REF,
                $SCALAR_REF_REF,
                $ARRAY_REF,
                $HASH_REF,
                $CODE_REF,
                $GLOB,
                $GLOB_REF,
                $FH,
                $UNDEF,
            ],
        }
    );
}

{
    note 'Combined Union Test';
    my $union = union( [ 'Int', enum( [qw[ red green blue ]] ) ] );

    test_constraint(
        $union, {
            accept => [
                $ZERO,
                $ONE,
                $INT,
                $NEG_INT,
                'red',
                'green',
                'blue',
            ],
            reject => [
                'yellow',
                'pink',
                $FH_OBJECT,
                $REGEX,
                $REGEX_OBJ,
                $FAKE_REGEX,
                $OBJECT,
                $NUM,
                $NEG_NUM,
                $EMPTY_STRING,
                $STRING,
                $NUM_IN_STRING,
                $INT_WITH_NL1,
                $INT_WITH_NL2,
                $SCALAR_REF,
                $SCALAR_REF_REF,
                $ARRAY_REF,
                $HASH_REF,
                $CODE_REF,
                $GLOB,
                $GLOB_REF,
                $FH,
                $UNDEF,
            ],
        }
    );
}


{
    enum 'Enum1' => 'a', 'b';
    enum 'Enum2' => 'x', 'y';

    subtype 'EnumUnion', as 'Enum1 | Enum2';

    test_constraint(
        'EnumUnion', {
            accept => [qw( a b x y )],
            reject => [
                $ZERO,
                $ONE,
                $INT,
                $NEG_INT,
                $NUM,
                $NEG_NUM,
                $EMPTY_STRING,
                $STRING,
                $NUM_IN_STRING,
                $INT_WITH_NL1,
                $INT_WITH_NL2,
                $SCALAR_REF,
                $SCALAR_REF_REF,
                $ARRAY_REF,
                $HASH_REF,
                $CODE_REF,
                $GLOB,
                $GLOB_REF,
                $FH,
                $FH_OBJECT,
                $REGEX,
                $REGEX_OBJ,
                $FAKE_REGEX,
                $OBJECT,
                $UNDEF,
            ],
        }
    );
}

{
    package DoesRole;

    use Moose;

    with 'Role';
}

# Test how $_ is used in XS implementation
{
    local $_ = qr/./;
    ok(
        Moose::Util::TypeConstraints::Builtins::_RegexpRef(),
        '$_ is RegexpRef'
    );
    ok(
        !Moose::Util::TypeConstraints::Builtins::_RegexpRef(1),
        '$_ is not read when param provided'
    );

    $_ = bless qr/./, 'Blessed';

    ok(
        Moose::Util::TypeConstraints::Builtins::_RegexpRef(),
        '$_ is RegexpRef'
    );

    $_ = 42;
    ok(
        !Moose::Util::TypeConstraints::Builtins::_RegexpRef(),
        '$_ is not RegexpRef'
    );
    ok(
        Moose::Util::TypeConstraints::Builtins::_RegexpRef(qr/./),
        '$_ is not read when param provided'
    );
}

close $FH
    or warn "Could not close the filehandle $0 for test";
$FH_OBJECT->close
    or warn "Could not close the filehandle $0 for test";

done_testing;

sub test_constraint {
    my $type  = shift;
    my $tests = shift;

    local $Test::Builder::Level = $Test::Builder::Level + 1;

    unless ( blessed $type ) {
        $type = Moose::Util::TypeConstraints::find_type_constraint($type)
            or BAIL_OUT("No such type $type!");
    }

    my $name = $type->name;

    my $unoptimized
        = $type->has_parent
        ? $type->_compile_subtype( $type->constraint )
        : $type->_compile_type( $type->constraint );

    my $inlined;
    if ( $type->can_be_inlined ) {
        $inlined = eval_closure(
            source      => 'sub { ( ' . $type->_inline_check('$_[0]') . ' ) }',
            environment => $type->inline_environment,
        );
    }

    my $class = Moose::Meta::Class->create_anon(
        superclasses => ['Moose::Object'],
    );
    $class->add_attribute(
        simple => (
            is  => 'ro',
            isa => $type,
        )
    );

    $class->add_attribute(
        collection => (
            traits  => ['Array'],
            isa     => 'ArrayRef[' . $type->name . ']',
            default => sub { [] },
            handles => { add_to_collection => 'push' },
        )
    );

    my $anon_class = $class->name;

    for my $accept ( @{ $tests->{accept} || [] } ) {
        my $described = describe($accept);
        ok(
            $type->check($accept),
            "$name accepts $described using ->check"
        );
        ok(
            $unoptimized->($accept),
            "$name accepts $described using unoptimized constraint"
        );
        if ($inlined) {
            ok(
                $inlined->($accept),
                "$name accepts $described using inlined constraint"
            );
        }

        is(
            exception {
                $anon_class->new( simple => $accept );
            },
            undef,
            "no exception passing $described to constructor with $name"
        );

        is(
            exception {
                $anon_class->new()->add_to_collection($accept);
            },
            undef,
            "no exception passing $described to native trait push method with $name"
        );
    }

    for my $reject ( @{ $tests->{reject} || [] } ) {
        my $described = describe($reject);
        ok(
            !$type->check($reject),
            "$name rejects $described using ->check"
        );
        ok(
            !$unoptimized->($reject),
            "$name rejects $described using unoptimized constraint"
        );
        if ($inlined) {
            ok(
                !$inlined->($reject),
                "$name rejects $described using inlined constraint"
            );
        }

        ok(
            exception {
                $anon_class->new( simple => $reject );
            },
            "got exception passing $described to constructor with $name"
        );

        ok(
            exception {
                $anon_class->new()->add_to_collection($reject);
            },
            "got exception passing $described to native trait push method with $name"
        );
    }
}

sub describe {
    my $val = shift;

    return 'undef' unless defined $val;

    if ( !ref $val ) {
        return q{''} if $val eq q{};

        $val =~ s/\n/\\n/g;

        return $val;
    }

    return 'open filehandle'
        if openhandle $val && !blessed $val;

    return blessed $val
        ? ( ref $val ) . ' object'
        : ( ref $val ) . ' reference';
}
