#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;

use Moose::Util::TypeConstraints;

my $type = Moose::Util::TypeConstraints::find_or_parse_type_constraint('Maybe[Int]');
isa_ok($type, 'Moose::Meta::TypeConstraint');
isa_ok($type, 'Moose::Meta::TypeConstraint::Parameterized');

ok( $type->equals($type), "equals self" );
ok( !$type->equals($type->parent), "not equal to parent" );
ok( !$type->equals(find_type_constraint("Maybe")), "not equal to Maybe" );
ok( $type->parent->equals(find_type_constraint("Maybe")), "parent is Maybe" );
ok( $type->equals( Moose::Meta::TypeConstraint::Parameterized->new( name => "__ANON__", parent => find_type_constraint("Maybe"), type_parameter => find_type_constraint("Int") ) ), "equal to clone" );
ok( !$type->equals( Moose::Meta::TypeConstraint::Parameterized->new( name => "__ANON__", parent => find_type_constraint("Maybe"), type_parameter => find_type_constraint("Str") ) ), "not equal to clone with diff param" );
ok( !$type->equals( Moose::Util::TypeConstraints::find_or_parse_type_constraint('Maybe[Str]') ), "not equal to declarative version of diff param" );

ok($type->check(10), '... checked type correctly (pass)');
ok($type->check(undef), '... checked type correctly (pass)');
ok(!$type->check('Hello World'), '... checked type correctly (fail)');
ok(!$type->check([]), '... checked type correctly (fail)');

{
    package Bar;
    use Moose;

    package Foo;
    use Moose;
    use Moose::Util::TypeConstraints;

    has 'arr' => (is => 'rw', isa => 'Maybe[ArrayRef]', required => 1);
    has 'bar' => (is => 'rw', isa => class_type('Bar'));
    has 'maybe_bar' => (is => 'rw', isa => maybe_type(class_type('Bar')));
}

is( exception {
    Foo->new(arr => [], bar => Bar->new);
}, undef, '... Bar->new isa Bar' );

isnt( exception {
    Foo->new(arr => [], bar => undef);
}, undef, '... undef isnta Bar' );

is( exception {
    Foo->new(arr => [], maybe_bar => Bar->new);
}, undef, '... Bar->new isa maybe(Bar)' );

is( exception {
    Foo->new(arr => [], maybe_bar => undef);
}, undef, '... undef isa maybe(Bar)' );

isnt( exception {
    Foo->new(arr => [], maybe_bar => 1);
}, undef, '... 1 isnta maybe(Bar)' );

is( exception {
    Foo->new(arr => []);
}, undef, '... it worked!' );

is( exception {
    Foo->new(arr => undef);
}, undef, '... it worked!' );

isnt( exception {
    Foo->new(arr => 100);
}, undef, '... failed the type check' );

isnt( exception {
    Foo->new(arr => 'hello world');
}, undef, '... failed the type check' );


{
    package Test::MooseX::Types::Maybe;
    use Moose;

    has 'Maybe_Int' => (is=>'rw', isa=>'Maybe[Int]');
    has 'Maybe_ArrayRef' => (is=>'rw', isa=>'Maybe[ArrayRef]');
    has 'Maybe_HashRef' => (is=>'rw', isa=>'Maybe[HashRef]');
    has 'Maybe_ArrayRefInt' => (is=>'rw', isa=>'Maybe[ArrayRef[Int]]');
    has 'Maybe_HashRefInt' => (is=>'rw', isa=>'Maybe[HashRef[Int]]');
}

ok my $obj = Test::MooseX::Types::Maybe->new
 => 'Create good test object';

##  Maybe[Int]

ok my $Maybe_Int  = Moose::Util::TypeConstraints::find_or_parse_type_constraint('Maybe[Int]')
 => 'made TC Maybe[Int]';

ok $Maybe_Int->check(1)
 => 'passed (1)';

ok $obj->Maybe_Int(1)
 => 'assigned (1)';

ok $Maybe_Int->check()
 => 'passed ()';

ok $obj->Maybe_Int()
 => 'assigned ()';

ok $Maybe_Int->check(0)
 => 'passed (0)';

ok defined $obj->Maybe_Int(0)
 => 'assigned (0)';

ok $Maybe_Int->check(undef)
 => 'passed (undef)';

ok sub {$obj->Maybe_Int(undef); 1}->()
 => 'assigned (undef)';

ok !$Maybe_Int->check("")
 => 'failed ("")';

like( exception { $obj->Maybe_Int("") }, qr/Attribute \(Maybe_Int\) does not pass the type constraint/, 'failed assigned ("")' );

ok !$Maybe_Int->check("a")
 => 'failed ("a")';

like( exception { $obj->Maybe_Int("a") }, qr/Attribute \(Maybe_Int\) does not pass the type constraint/, 'failed assigned ("a")' );

done_testing;
