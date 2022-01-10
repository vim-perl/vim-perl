#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;
use Scalar::Util qw(refaddr);

use Moose::Util::TypeConstraints;

# subtype 'aliasing' ...

is( exception {
    subtype 'Numb3rs' => as 'Num';
}, undef, '... create bare subtype fine' );

my $numb3rs = find_type_constraint('Numb3rs');
isa_ok($numb3rs, 'Moose::Meta::TypeConstraint');

# subtype with unions

{
    package Test::Moose::Meta::TypeConstraint::Union;

    use overload '""' => sub {'Broken|Test'}, fallback => 1;
    use Moose;

    extends 'Moose::Meta::TypeConstraint';
}

my $dummy_instance = Test::Moose::Meta::TypeConstraint::Union->new;

ok $dummy_instance => "Created Instance";

isa_ok $dummy_instance,
    'Test::Moose::Meta::TypeConstraint::Union' => 'isa correct type';

is "$dummy_instance", "Broken|Test" =>
    'Got expected stringification result';

my $subtype1 = subtype 'New1' => as $dummy_instance;

ok $subtype1 => 'made a subtype from our type object';

my $subtype2 = subtype 'New2' => as $subtype1;

ok $subtype2 => 'made a subtype of our subtype';

# assert_valid

{
    my $type = find_type_constraint('Num');

    my $ok_1 = eval { $type->assert_valid(1); };
    ok($ok_1, "we can assert_valid that 1 is of type $type");

    my $ok_2 = eval { $type->assert_valid('foo'); };
    my $error = $@;
    ok(! $ok_2, "'foo' is not of type $type");
    like(
        $error,
        qr{validation failed for .\Q$type\E.}i,
        "correct error thrown"
    );
}

{
    for my $t (qw(Bar Foo)) {
        my $tc = Moose::Meta::TypeConstraint->new({
            name => $t,
        });

        Moose::Util::TypeConstraints::register_type_constraint($tc);
    }

    my $foo = Moose::Util::TypeConstraints::find_type_constraint('Foo');
    my $bar = Moose::Util::TypeConstraints::find_type_constraint('Bar');

    ok(!$foo->equals($bar), "Foo type is not equal to Bar type");
    ok( $foo->equals($foo), "Foo equals Foo");
    ok( 0+$foo == refaddr($foo), "overloading works");
}

ok $subtype1, "type constraint boolean overload works";

done_testing;
