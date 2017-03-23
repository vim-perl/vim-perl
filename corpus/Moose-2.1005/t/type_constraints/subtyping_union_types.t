#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;

use Moose::Util::TypeConstraints;

is( exception {
    subtype 'MyCollections' => as 'ArrayRef | HashRef';
}, undef, '... created the subtype special okay' );

{
    my $t = find_type_constraint('MyCollections');
    isa_ok($t, 'Moose::Meta::TypeConstraint');

    is($t->name, 'MyCollections', '... name is correct');

    my $p = $t->parent;
    isa_ok($p, 'Moose::Meta::TypeConstraint::Union');
    isa_ok($p, 'Moose::Meta::TypeConstraint');

    is($p->name, 'ArrayRef|HashRef', '... parent name is correct');

    ok($t->check([]), '... validated it correctly');
    ok($t->check({}), '... validated it correctly');
    ok(!$t->check(1), '... validated it correctly');
}

is( exception {
    subtype 'MyCollectionsExtended'
        => as 'ArrayRef|HashRef'
        => where {
            if (ref($_) eq 'ARRAY') {
                return if scalar(@$_) < 2;
            }
            elsif (ref($_) eq 'HASH') {
                return if scalar(keys(%$_)) < 2;
            }
            1;
        };
}, undef, '... created the subtype special okay' );

{
    my $t = find_type_constraint('MyCollectionsExtended');
    isa_ok($t, 'Moose::Meta::TypeConstraint');

    is($t->name, 'MyCollectionsExtended', '... name is correct');

    my $p = $t->parent;
    isa_ok($p, 'Moose::Meta::TypeConstraint::Union');
    isa_ok($p, 'Moose::Meta::TypeConstraint');

    is($p->name, 'ArrayRef|HashRef', '... parent name is correct');

    ok(!$t->check([]), '... validated it correctly');
    ok($t->check([1, 2]), '... validated it correctly');

    ok(!$t->check({}), '... validated it correctly');
    ok($t->check({ one => 1, two => 2 }), '... validated it correctly');

    ok(!$t->check(1), '... validated it correctly');
}

{
    my $union = Moose::Util::TypeConstraints::find_or_create_type_constraint('Int|ArrayRef[Int]');
    subtype 'UnionSub', as 'Int|ArrayRef[Int]';

    my $subtype = find_type_constraint('UnionSub');

    ok(
        !$union->is_a_type_of('Ref'),
        'Int|ArrayRef[Int] is not a type of Ref'
    );
    ok(
        !$subtype->is_a_type_of('Ref'),
        'subtype of Int|ArrayRef[Int] is not a type of Ref'
    );

    ok(
        $union->is_a_type_of('Defined'),
        'Int|ArrayRef[Int] is a type of Defined'
    );
    ok(
        $subtype->is_a_type_of('Defined'),
        'subtype of Int|ArrayRef[Int] is a type of Defined'
    );

    ok(
        !$union->is_subtype_of('Ref'),
        'Int|ArrayRef[Int] is not a subtype of Ref'
    );
    ok(
        !$subtype->is_subtype_of('Ref'),
        'subtype of Int|ArrayRef[Int] is not a subtype of Ref'
    );

    ok(
        $union->is_subtype_of('Defined'),
        'Int|ArrayRef[Int] is a subtype of Defined'
    );
    ok(
        $subtype->is_subtype_of('Defined'),
        'subtype of Int|ArrayRef[Int] is a subtype of Defined'
    );
}

done_testing;
