#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;

use Moose::Util::TypeConstraints;

{
    package Gorch;
    use Moose;

    package Bar;
    use Moose;

    package Foo;
    use Moose;

    extends qw(Bar Gorch);

}

is( exception { class_type 'Beep' }, undef, 'class_type keywork works' );
is( exception { class_type('Boop', message { "${_} is not a Boop" }) }, undef, 'class_type keywork works with message' );

my $type = find_type_constraint("Foo");

is( $type->class, "Foo", "class attribute" );

ok( !$type->is_subtype_of('Foo'), "Foo is not subtype of Foo" );
ok( !$type->is_subtype_of($type), '$foo_type is not subtype of $foo_type' );

ok( $type->is_subtype_of("Gorch"), "subtype of gorch" );

ok( $type->is_subtype_of("Bar"), "subtype of bar" );

ok( $type->is_subtype_of("Object"), "subtype of Object" );

ok( !$type->is_subtype_of("ThisTypeDoesNotExist"), "not subtype of undefined type" );
ok( !$type->is_a_type_of("ThisTypeDoesNotExist"), "not type of undefined type" );

ok( find_type_constraint("Bar")->check(Foo->new), "Foo passes Bar" );
ok( find_type_constraint("Bar")->check(Bar->new), "Bar passes Bar" );
ok( !find_type_constraint("Gorch")->check(Bar->new), "but Bar doesn't pass Gorch");

ok( find_type_constraint("Beep")->check( bless {} => 'Beep' ), "Beep passes Beep" );
my $boop = find_type_constraint("Boop");
ok( $boop->has_message, 'Boop has a message');
my $error = $boop->get_message(Foo->new);
like( $error, qr/is not a Boop/,  'boop gives correct error message');


ok( $type->equals($type), "equals self" );
ok( $type->equals(Moose::Meta::TypeConstraint::Class->new( name => "__ANON__", class => "Foo" )), "equals anon constraint of same value" );
ok( $type->equals(Moose::Meta::TypeConstraint::Class->new( name => "Oink", class => "Foo" )), "equals differently named constraint of same value" );
ok( !$type->equals(Moose::Meta::TypeConstraint::Class->new( name => "__ANON__", class => "Bar" )), "doesn't equal other anon constraint" );
ok( $type->is_subtype_of(Moose::Meta::TypeConstraint::Class->new( name => "__ANON__", class => "Bar" )), "subtype of other anon constraint" );

{
    package Parent;
    sub parent { }
}

{
    package Child;
    use base 'Parent';
}

{
    my $parent = Moose::Meta::TypeConstraint::Class->new(
        name  => 'Parent',
        class => 'Parent',
    );
    ok($parent->is_a_type_of('Parent'));
    ok(!$parent->is_subtype_of('Parent'));
    ok($parent->is_a_type_of($parent));
    ok(!$parent->is_subtype_of($parent));

    my $child = Moose::Meta::TypeConstraint::Class->new(
        name  => 'Child',
        class => 'Child',
    );
    ok($child->is_a_type_of('Child'));
    ok(!$child->is_subtype_of('Child'));
    ok($child->is_a_type_of($child));
    ok(!$child->is_subtype_of($child));
    ok($child->is_a_type_of('Parent'));
    ok($child->is_subtype_of('Parent'));
    ok($child->is_a_type_of($parent));
    ok($child->is_subtype_of($parent));
}

{
    my $type;
    is( exception { $type = class_type 'MyExampleClass' }, undef, 'Make initial class_type' );
    coerce 'MyExampleClass', from 'Str', via { bless {}, 'MyExampleClass' };
    # We test class_type keeping the existing type (not making a new one) here.
    is( exception { is(class_type('MyExampleClass'), $type, 're-running class_type gives same type') }, undef, 'No exception making duplicate class_type' );;

    # Next define a class which needs this type and it's original coercion
    # Note this has to be after the 2nd class_type call to test the bug as M::M::Attribute grabs
    # the type constraint which is there at the time the attribute decleration runs.
    {
        package HoldsExample;
        use Moose;

        has foo => ( isa => 'MyExampleClass', is => 'ro', coerce => 1, required => 1 );
        no Moose;
    }

    is( exception { isa_ok(HoldsExample->new(foo => "bar")->foo, 'MyExampleClass') }, undef, 'class_type coercion works' );
}

done_testing;
