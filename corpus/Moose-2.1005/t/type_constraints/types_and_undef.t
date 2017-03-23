#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;


{
    package Foo;
    use Moose;
    use Moose::Util::TypeConstraints;

    use Scalar::Util ();

    type Number
        => where { defined($_) && !ref($_) && Scalar::Util::looks_like_number($_) };

    type String
        => where { defined($_) && !ref($_) && !Scalar::Util::looks_like_number($_) };

    has vUndef   => ( is => 'rw', isa => 'Undef'   );
    has vDefined => ( is => 'rw', isa => 'Defined' );
    has vInt     => ( is => 'rw', isa => 'Int'     );
    has vNumber  => ( is => 'rw', isa => 'Number'  );
    has vStr     => ( is => 'rw', isa => 'Str'     );
    has vString  => ( is => 'rw', isa => 'String'  );

    has v_lazy_Undef   => ( is => 'rw', lazy => 1,  default => sub { undef }, isa => 'Undef'   );
    has v_lazy_Defined => ( is => 'rw', lazy => 1,  default => sub { undef }, isa => 'Defined' );
    has v_lazy_Int     => ( is => 'rw', lazy => 1,  default => sub { undef }, isa => 'Int'     );
    has v_lazy_Number  => ( is => 'rw', lazy => 1,  default => sub { undef }, isa => 'Number'  );
    has v_lazy_Str     => ( is => 'rw', lazy => 1,  default => sub { undef }, isa => 'Str'     );
    has v_lazy_String  => ( is => 'rw', lazy => 1,  default => sub { undef }, isa => 'String'  );
}

#    EXPORT TYPE CONSTRAINTS
#
Moose::Util::TypeConstraints->export_type_constraints_as_functions;

ok( Undef(undef),   '... undef is a Undef');
ok(!Defined(undef), '... undef is NOT a Defined');
ok(!Int(undef),     '... undef is NOT an Int');
ok(!Number(undef),  '... undef is NOT a Number');
ok(!Str(undef),     '... undef is NOT a Str');
ok(!String(undef),  '... undef is NOT a String');

ok(!Undef(5),  '... 5 is a NOT a Undef');
ok(Defined(5), '... 5 is a Defined');
ok(Int(5),     '... 5 is an Int');
ok(Number(5),  '... 5 is a Number');
ok(Str(5),     '... 5 is a Str');
ok(!String(5), '... 5 is NOT a String');

ok(!Undef(0.5),  '... 0.5 is a NOT a Undef');
ok(Defined(0.5), '... 0.5 is a Defined');
ok(!Int(0.5),    '... 0.5 is NOT an Int');
ok(Number(0.5),  '... 0.5 is a Number');
ok(Str(0.5),     '... 0.5 is a Str');
ok(!String(0.5), '... 0.5 is NOT a String');

ok(!Undef('Foo'),  '... "Foo" is NOT a Undef');
ok(Defined('Foo'), '... "Foo" is a Defined');
ok(!Int('Foo'),    '... "Foo" is NOT an Int');
ok(!Number('Foo'), '... "Foo" is NOT a Number');
ok(Str('Foo'),     '... "Foo" is a Str');
ok(String('Foo'),  '... "Foo" is a String');


my $foo = Foo->new;

is( exception { $foo->vUndef(undef) }, undef, '... undef is a Foo->Undef' );
isnt( exception { $foo->vDefined(undef) }, undef, '... undef is NOT a Foo->Defined' );
isnt( exception { $foo->vInt(undef) }, undef, '... undef is NOT a Foo->Int' );
isnt( exception { $foo->vNumber(undef) }, undef, '... undef is NOT a Foo->Number' );
isnt( exception { $foo->vStr(undef) }, undef, '... undef is NOT a Foo->Str' );
isnt( exception { $foo->vString(undef) }, undef, '... undef is NOT a Foo->String' );

isnt( exception { $foo->vUndef(5) }, undef, '... 5 is NOT a Foo->Undef' );
is( exception { $foo->vDefined(5) }, undef, '... 5 is a Foo->Defined' );
is( exception { $foo->vInt(5) }, undef, '... 5 is a Foo->Int' );
is( exception { $foo->vNumber(5) }, undef, '... 5 is a Foo->Number' );
is( exception { $foo->vStr(5) }, undef, '... 5 is a Foo->Str' );
isnt( exception { $foo->vString(5) }, undef, '... 5 is NOT a Foo->String' );

isnt( exception { $foo->vUndef(0.5) }, undef, '... 0.5 is NOT a Foo->Undef' );
is( exception { $foo->vDefined(0.5) }, undef, '... 0.5 is a Foo->Defined' );
isnt( exception { $foo->vInt(0.5) }, undef, '... 0.5 is NOT a Foo->Int' );
is( exception { $foo->vNumber(0.5) }, undef, '... 0.5 is a Foo->Number' );
is( exception { $foo->vStr(0.5) }, undef, '... 0.5 is a Foo->Str' );
isnt( exception { $foo->vString(0.5) }, undef, '... 0.5 is NOT a Foo->String' );

isnt( exception { $foo->vUndef('Foo') }, undef, '... "Foo" is NOT a Foo->Undef' );
is( exception { $foo->vDefined('Foo') }, undef, '... "Foo" is a Foo->Defined' );
isnt( exception { $foo->vInt('Foo') }, undef, '... "Foo" is NOT a Foo->Int' );
isnt( exception { $foo->vNumber('Foo') }, undef, '... "Foo" is NOT a Foo->Number' );
is( exception { $foo->vStr('Foo') }, undef, '... "Foo" is a Foo->Str' );
is( exception { $foo->vString('Foo') }, undef, '... "Foo" is a Foo->String' );

# the lazy tests

is( exception { $foo->v_lazy_Undef() }, undef, '... undef is a Foo->Undef' );
isnt( exception { $foo->v_lazy_Defined() }, undef, '... undef is NOT a Foo->Defined' );
isnt( exception { $foo->v_lazy_Int() }, undef, '... undef is NOT a Foo->Int' );
isnt( exception { $foo->v_lazy_Number() }, undef, '... undef is NOT a Foo->Number' );
isnt( exception { $foo->v_lazy_Str() }, undef, '... undef is NOT a Foo->Str' );
isnt( exception { $foo->v_lazy_String() }, undef, '... undef is NOT a Foo->String' );

done_testing;
