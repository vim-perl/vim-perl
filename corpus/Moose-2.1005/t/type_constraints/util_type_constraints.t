#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;

use Scalar::Util ();

use Moose::Util::TypeConstraints;


type Number => where { Scalar::Util::looks_like_number($_) };
type String
    => where { !ref($_) && !Number($_) }
    => message { "This is not a string ($_)" };

subtype Natural
        => as Number
        => where { $_ > 0 };

subtype NaturalLessThanTen
        => as Natural
        => where { $_ < 10 }
        => message { "The number '$_' is not less than 10" };

Moose::Util::TypeConstraints->export_type_constraints_as_functions();

ok(Number(5), '... this is a Num');
ok(!defined(Number('Foo')), '... this is not a Num');
{
    my $number_tc = Moose::Util::TypeConstraints::find_type_constraint('Number');
    is("$number_tc", 'Number', '... type constraint stringifies to name');
}

ok(String('Foo'), '... this is a Str');
ok(!defined(String(5)), '... this is not a Str');

ok(Natural(5), '... this is a Natural');
is(Natural(-5), undef, '... this is not a Natural');
is(Natural('Foo'), undef, '... this is not a Natural');

ok(NaturalLessThanTen(5), '... this is a NaturalLessThanTen');
is(NaturalLessThanTen(12), undef, '... this is not a NaturalLessThanTen');
is(NaturalLessThanTen(-5), undef, '... this is not a NaturalLessThanTen');
is(NaturalLessThanTen('Foo'), undef, '... this is not a NaturalLessThanTen');

# anon sub-typing

my $negative = subtype Number => where  { $_ < 0 };
ok(defined $negative, '... got a value back from negative');
isa_ok($negative, 'Moose::Meta::TypeConstraint');

ok($negative->check(-5), '... this is a negative number');
ok(!defined($negative->check(5)), '... this is not a negative number');
is($negative->check('Foo'), undef, '... this is not a negative number');

ok($negative->is_subtype_of('Number'), '... $negative is a subtype of Number');
ok(!$negative->is_subtype_of('String'), '... $negative is not a subtype of String');

my $negative2 = subtype Number => where { $_ < 0 } => message {"$_ is not a negative number"};

ok(defined $negative2, '... got a value back from negative');
isa_ok($negative2, 'Moose::Meta::TypeConstraint');

ok($negative2->check(-5), '... this is a negative number');
ok(!defined($negative2->check(5)), '... this is not a negative number');
is($negative2->check('Foo'), undef, '... this is not a negative number');

ok($negative2->is_subtype_of('Number'), '... $negative2 is a subtype of Number');
ok(!$negative2->is_subtype_of('String'), '... $negative is not a subtype of String');

ok($negative2->has_message, '... it has a message');
is($negative2->validate(2),
   '2 is not a negative number',
   '... validated unsuccessfully (got error)');

# check some meta-details

my $natural_less_than_ten = find_type_constraint('NaturalLessThanTen');
isa_ok($natural_less_than_ten, 'Moose::Meta::TypeConstraint');

ok($natural_less_than_ten->is_subtype_of('Natural'), '... NaturalLessThanTen is subtype of Natural');
ok($natural_less_than_ten->is_subtype_of('Number'), '... NaturalLessThanTen is subtype of Number');
ok(!$natural_less_than_ten->is_subtype_of('String'), '... NaturalLessThanTen is not subtype of String');

ok($natural_less_than_ten->has_message, '... it has a message');

ok(!defined($natural_less_than_ten->validate(5)), '... validated successfully (no error)');

is($natural_less_than_ten->validate(15),
   "The number '15' is not less than 10",
   '... validated unsuccessfully (got error)');

my $natural = find_type_constraint('Natural');
isa_ok($natural, 'Moose::Meta::TypeConstraint');

ok($natural->is_subtype_of('Number'), '... Natural is a subtype of Number');
ok(!$natural->is_subtype_of('String'), '... Natural is not a subtype of String');

ok(!$natural->has_message, '... it does not have a message');

ok(!defined($natural->validate(5)), '... validated successfully (no error)');

is($natural->validate(-5),
  "Validation failed for 'Natural' with value -5",
  '... validated unsuccessfully (got error)');

my $string = find_type_constraint('String');
isa_ok($string, 'Moose::Meta::TypeConstraint');

ok($string->has_message, '... it does have a message');

ok(!defined($string->validate("Five")), '... validated successfully (no error)');

is($string->validate(5),
"This is not a string (5)",
'... validated unsuccessfully (got error)');

is( exception { Moose::Meta::Attribute->new('bob', isa => 'Spong') }, undef, 'meta-attr construction ok even when type constraint utils loaded first' );

# Test type constraint predicate return values.

foreach my $predicate (qw/equals is_subtype_of is_a_type_of/) {
    ok( !defined $string->$predicate('DoesNotExist'), "$predicate predicate returns undef for non existant constraint");
}

# Test adding things which don't look like types to the registry throws an exception

my $r = Moose::Util::TypeConstraints->get_type_constraint_registry;
like( exception {$r->add_type_constraint()}, qr/not a valid type constraint/, '->add_type_constraint(undef) throws' );
like( exception {$r->add_type_constraint('foo')}, qr/not a valid type constraint/, '->add_type_constraint("foo") throws' );
like( exception {$r->add_type_constraint(bless {}, 'SomeClass')}, qr/not a valid type constraint/, '->add_type_constraint(SomeClass->new) throws' );

# Test some specific things that in the past did not work,
# specifically weird variations on anon subtypes.

{
    my $subtype = subtype as 'Str';
    isa_ok( $subtype, 'Moose::Meta::TypeConstraint', 'got an anon subtype' );
    is( $subtype->parent->name, 'Str', 'parent is Str' );
    # This test sucks but is the best we can do
    is( $subtype->constraint->(), 1,
        'subtype has the null constraint' );
    ok( ! $subtype->has_message, 'subtype has no message' );
}

{
    my $subtype = subtype as 'ArrayRef[Num|Str]';
    isa_ok( $subtype, 'Moose::Meta::TypeConstraint', 'got an anon subtype' );
    is( $subtype->parent->name, 'ArrayRef[Num|Str]', 'parent is ArrayRef[Num|Str]' );
    ok( ! $subtype->has_message, 'subtype has no message' );
}

{
    my $subtype = subtype 'ArrayRef[Num|Str]' => message { 'foo' };
    isa_ok( $subtype, 'Moose::Meta::TypeConstraint', 'got an anon subtype' );
    is( $subtype->parent->name, 'ArrayRef[Num|Str]', 'parent is ArrayRef[Num|Str]' );
    ok( $subtype->has_message, 'subtype does have a message' );
}

# alternative sugar-less calling style which is documented as legit:
{
    my $subtype = subtype( 'MyStr', { as => 'Str' } );
    isa_ok( $subtype, 'Moose::Meta::TypeConstraint', 'got a subtype' );
    is( $subtype->name, 'MyStr', 'name is MyStr' );
    is( $subtype->parent->name, 'Str', 'parent is Str' );
}

{
    my $subtype = subtype( { as => 'Str' } );
    isa_ok( $subtype, 'Moose::Meta::TypeConstraint', 'got a subtype' );
    is( $subtype->name, '__ANON__', 'name is __ANON__' );
    is( $subtype->parent->name, 'Str', 'parent is Str' );
}

{
    my $subtype = subtype( { as => 'Str', where => sub { /X/ } } );
    isa_ok( $subtype, 'Moose::Meta::TypeConstraint', 'got a subtype' );
    is( $subtype->name, '__ANON__', 'name is __ANON__' );
    is( $subtype->parent->name, 'Str', 'parent is Str' );
    ok( $subtype->check('FooX'), 'constraint accepts FooX' );
    ok( ! $subtype->check('Foo'), 'constraint reject Foo' );
}

{
    like( exception { subtype 'Foo' }, qr/cannot consist solely of a name/, 'Cannot call subtype with a single string argument' );
}

{
    my $subtype = subtype( { as => 'Num' } );
    isa_ok( $subtype, 'Moose::Meta::TypeConstraint', 'got a subtype' );

    my @rejects = ( 'nan',
            'inf',
            'infinity',
            'Infinity',
            'NaN',
            'INF',
            '  1234  ',
            '  123.44  ',
            '   13e7  ',
            'hello',
            "1e3\n",
            "52563\n",
            "123.4\n",
            '0.',
            "0 but true",
            undef
    );
    my @accepts = ( '123',
            '123.4367',
            '3322',
            '13e7',
            '0',
            '0.0',
            '.0',
            .0,
            0.0,
            123,
            13e6,
            123.4367,
            10.5
    );

    for( @rejects )
    {
        my $printable = defined $_ ? $_ : "(undef)";
        ok( !$subtype->check($_), "constraint rejects $printable" )
    }
    ok( $subtype->check($_), "constraint accepts $_" ) for @accepts;
}

done_testing;
