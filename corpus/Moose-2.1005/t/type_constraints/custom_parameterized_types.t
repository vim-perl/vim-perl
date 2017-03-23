#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;

use Moose::Util::TypeConstraints;
use Moose::Meta::TypeConstraint::Parameterized;

is( exception {
    subtype 'AlphaKeyHash' => as 'HashRef'
        => where {
            # no keys match non-alpha
            (grep { /[^a-zA-Z]/ } keys %$_) == 0
        };
}, undef, '... created the subtype special okay' );

is( exception {
    subtype 'Trihash' => as 'AlphaKeyHash'
        => where {
            keys(%$_) == 3
        };
}, undef, '... created the subtype special okay' );

is( exception {
    subtype 'Noncon' => as 'Item';
}, undef, '... created the subtype special okay' );

{
    my $t = find_type_constraint('AlphaKeyHash');
    isa_ok($t, 'Moose::Meta::TypeConstraint');

    is($t->name, 'AlphaKeyHash', '... name is correct');

    my $p = $t->parent;
    isa_ok($p, 'Moose::Meta::TypeConstraint');

    is($p->name, 'HashRef', '... parent name is correct');

    ok($t->check({ one => 1, two => 2 }), '... validated it correctly');
    ok(!$t->check({ one1 => 1, two2 => 2 }), '... validated it correctly');

    ok( $t->equals($t), "equals to self" );
    ok( !$t->equals($t->parent), "not equal to parent" );
}

my $hoi = Moose::Util::TypeConstraints::find_or_parse_type_constraint('AlphaKeyHash[Int]');

ok($hoi->check({ one => 1, two => 2 }), '... validated it correctly');
ok(!$hoi->check({ one1 => 1, two2 => 2 }), '... validated it correctly');
ok(!$hoi->check({ one => 'uno', two => 'dos' }), '... validated it correctly');
ok(!$hoi->check({ one1 => 'un', two2 => 'deux' }), '... validated it correctly');

ok( $hoi->equals($hoi), "equals to self" );
ok( !$hoi->equals($hoi->parent), "equals to self" );
ok( !$hoi->equals(find_type_constraint('AlphaKeyHash')), "not equal to unparametrized self" );
ok( $hoi->equals( Moose::Meta::TypeConstraint::Parameterized->new( name => "Blah", parent => find_type_constraint("AlphaKeyHash"), type_parameter => find_type_constraint("Int") ) ), "equal to clone" );
ok( !$hoi->equals( Moose::Meta::TypeConstraint::Parameterized->new( name => "Oink", parent => find_type_constraint("AlphaKeyHash"), type_parameter => find_type_constraint("Str") ) ), "not equal to different parameter" );

my $th = Moose::Util::TypeConstraints::find_or_parse_type_constraint('Trihash[Bool]');

ok(!$th->check({ one => 1, two => 1 }), '... validated it correctly');
ok($th->check({ one => 1, two => 0, three => 1 }), '... validated it correctly');
ok(!$th->check({ one => 1, two => 2, three => 1 }), '... validated it correctly');
ok(!$th->check({foo1 => 1, bar2 => 0, baz3 => 1}), '... validated it correctly');

isnt( exception {
    Moose::Meta::TypeConstraint::Parameterized->new(
        name           => 'Str[Int]',
        parent         => find_type_constraint('Str'),
        type_parameter => find_type_constraint('Int'),
    );
}, undef, 'non-containers cannot be parameterized' );

isnt( exception {
    Moose::Meta::TypeConstraint::Parameterized->new(
        name           => 'Noncon[Int]',
        parent         => find_type_constraint('Noncon'),
        type_parameter => find_type_constraint('Int'),
    );
}, undef, 'non-containers cannot be parameterized' );

done_testing;
