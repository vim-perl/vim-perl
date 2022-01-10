#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;

use Moose::Util::TypeConstraints;

is( exception {
    subtype 'MySpecialHash' => as 'HashRef[Int]';
}, undef, '... created the subtype special okay' );

{
    my $t = find_type_constraint('MySpecialHash');
    isa_ok($t, 'Moose::Meta::TypeConstraint');

    is($t->name, 'MySpecialHash', '... name is correct');

    my $p = $t->parent;
    isa_ok($p, 'Moose::Meta::TypeConstraint::Parameterized');
    isa_ok($p, 'Moose::Meta::TypeConstraint');

    is($p->name, 'HashRef[Int]', '... parent name is correct');

    ok($t->check({ one => 1, two => 2 }), '... validated {one=>1, two=>2} correctly');
    ok(!$t->check({ one => "ONE", two => "TWO" }), '... validated it correctly');

    ok( $t->equals($t), "equals to self" );
    ok( !$t->equals( $t->parent ), "not equal to parent" );
    ok( $t->parent->equals( $t->parent ), "parent equals to self" );

    ok( !$t->is_a_type_of("ThisTypeDoesNotExist"), "not a non existant type" );
    ok( !$t->is_subtype_of("ThisTypeDoesNotExist"), "not a subtype of a non existant type" );
}

is( exception {
    subtype 'MySpecialHashExtended'
        => as 'HashRef[Int]'
        => where {
            # all values are less then 10
            (scalar grep { $_ < 10 } values %{$_}) ? 1 : undef
        };
}, undef, '... created the subtype special okay' );

{
    my $t = find_type_constraint('MySpecialHashExtended');
    isa_ok($t, 'Moose::Meta::TypeConstraint');

    is($t->name, 'MySpecialHashExtended', '... name is correct');

    my $p = $t->parent;
    isa_ok($p, 'Moose::Meta::TypeConstraint::Parameterized');
    isa_ok($p, 'Moose::Meta::TypeConstraint');

    is($p->name, 'HashRef[Int]', '... parent name is correct');

    ok($t->check({ one => 1, two => 2 }), '... validated it correctly');
    ok(!$t->check({ zero => 10, one => 11, two => 12 }), '... validated { zero => 10, one => 11, two => 12 } correctly');
    ok(!$t->check({ one => "ONE", two => "TWO" }), '... validated it correctly');
}

is( exception {
    subtype 'MyNonSpecialHash'
        => as "HashRef"
        => where { keys %$_ == 3 };
}, undef );

{
    my $t = find_type_constraint('MyNonSpecialHash');

    isa_ok($t, 'Moose::Meta::TypeConstraint');
    isa_ok($t, 'Moose::Meta::TypeConstraint::Parameterizable');

    ok( $t->check({ one => 1, two => "foo", three => [] }), "validated" );
    ok( !$t->check({ one => 1 }), "failed" );
}

{
    my $t = Moose::Util::TypeConstraints::find_or_parse_type_constraint('MyNonSpecialHash[Int]');

    isa_ok($t, 'Moose::Meta::TypeConstraint');

    ok( $t->check({ one => 1, two => 2, three => 3 }), "validated" );
    ok( !$t->check({ one => 1, two => "foo", three => [] }), "failed" );
    ok( !$t->check({ one => 1 }), "failed" );
}

{
    ## Because to throw errors in M:M:Parameterizable needs Moose loaded in
    ## order to throw errors.  In theory the use Moose belongs to that class
    ## but when I put it there causes all sorts or trouble.  In theory this is
    ## never a real problem since you are likely to use Moose somewhere when you
    ## are creating type constraints.
    use Moose ();

    my $MyArrayRefInt =  subtype 'MyArrayRefInt',
        as 'ArrayRef[Int]';

    my $BiggerInt = subtype 'BiggerInt',
        as 'Int',
        where {$_>10};

    my $SubOfMyArrayRef = subtype 'SubOfMyArrayRef',
        as 'MyArrayRefInt[BiggerInt]';

    ok $MyArrayRefInt->check([1,2,3]), '[1,2,3] is okay';
    ok ! $MyArrayRefInt->check(["a","b"]), '["a","b"] is not';
    ok $BiggerInt->check(100), '100 is  big enough';
    ok ! $BiggerInt->check(5), '5 is  big enough';
    ok $SubOfMyArrayRef->check([15,20,25]), '[15,20,25] is a bunch of big ints';
    ok ! $SubOfMyArrayRef->check([15,5,25]), '[15,5,25] is NOT a bunch of big ints';

    like( exception {
        my $SubOfMyArrayRef = subtype 'SubSubOfMyArrayRef',
            as 'SubOfMyArrayRef[Str]';
    }, qr/Str is not a subtype of BiggerInt/, 'Failed to parameterize with a bad type parameter' );
}

{
    my $RefToInt = subtype as 'ScalarRef[Int]';

    ok $RefToInt->check(\1), '\1 is okay';
    ok !$RefToInt->check(1), '1 is not';
    ok !$RefToInt->check(\"foo"), '\"foo" is not';
}

done_testing;
