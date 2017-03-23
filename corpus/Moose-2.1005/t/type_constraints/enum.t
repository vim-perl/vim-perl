#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;

use Scalar::Util ();

use Moose::Util::TypeConstraints;

enum Letter => 'a'..'z', 'A'..'Z';
enum Language => 'Perl 5', 'Perl 6', 'PASM', 'PIR'; # any others? ;)
enum Metacharacter => ['*', '+', '?', '.', '|', '(', ')', '[', ']', '\\'];

my @valid_letters = ('a'..'z', 'A'..'Z');

my @invalid_letters = qw/ab abc abcd/;
push @invalid_letters, qw/0 4 9 ~ @ $ %/;
push @invalid_letters, qw/l33t st3v4n 3num/;

my @valid_languages = ('Perl 5', 'Perl 6', 'PASM', 'PIR');
my @invalid_languages = ('perl 5', 'Python', 'Ruby', 'Perl 666', 'PASM++');
# note that "perl 5" is invalid because case now matters

my @valid_metacharacters = (qw/* + ? . | ( ) [ ] /, '\\');
my @invalid_metacharacters = qw/< > & % $ @ ! ~ `/;
push @invalid_metacharacters, qw/.* fish(sticks)? atreides/;
push @invalid_metacharacters, '^1?$|^(11+?)\1+$';

Moose::Util::TypeConstraints->export_type_constraints_as_functions();

ok(Letter($_), "'$_' is a letter") for @valid_letters;
ok(!Letter($_), "'$_' is not a letter") for @invalid_letters;

ok(Language($_), "'$_' is a language") for @valid_languages;
ok(!Language($_), "'$_' is not a language") for @invalid_languages;

ok(Metacharacter($_), "'$_' is a metacharacter") for @valid_metacharacters;
ok(!Metacharacter($_), "'$_' is not a metacharacter")
    for @invalid_metacharacters;

# check anon enums

my $anon_enum = enum \@valid_languages;
isa_ok($anon_enum, 'Moose::Meta::TypeConstraint');

is($anon_enum->name, '__ANON__', '... got the right name');
is($anon_enum->parent->name, 'Str', '... got the right parent name');

ok($anon_enum->check($_), "'$_' is a language") for @valid_languages;


ok( !$anon_enum->equals( enum [qw(foo bar)] ), "doesn't equal a diff enum" );
ok( $anon_enum->equals( $anon_enum ), "equals itself" );
ok( $anon_enum->equals( enum \@valid_languages ), "equals duplicate" );

ok( !$anon_enum->is_subtype_of('Object'), 'enum not a subtype of Object');
ok( !$anon_enum->is_a_type_of('Object'), 'enum not type of Object');

ok( !$anon_enum->is_subtype_of('ThisTypeDoesNotExist'), 'enum not a subtype of nonexistant type');
ok( !$anon_enum->is_a_type_of('ThisTypeDoesNotExist'), 'enum not type of nonexistant type');

# validation
like( exception { Moose::Meta::TypeConstraint::Enum->new(name => 'ZeroValues', values => []) }, qr/You must have at least one value to enumerate through/ );

is( exception { Moose::Meta::TypeConstraint::Enum->new(name => 'OneValue', values => [ 'a' ]) }, undef);

like( exception { Moose::Meta::TypeConstraint::Enum->new(name => 'ReferenceInEnum', values => [ 'a', {} ]) }, qr/Enum values must be strings, not 'HASH\(0x\w+\)'/ );

like( exception { Moose::Meta::TypeConstraint::Enum->new(name => 'UndefInEnum', values => [ 'a', undef ]) }, qr/Enum values must be strings, not undef/ );

like( exception {
    package Foo;
    use Moose;
    use Moose::Util::TypeConstraints;

    has error => (
        is      => 'ro',
        isa     => enum ['a', 'aa', 'aaa'], # should be parenthesized!
        default => 'aa',
    );
}, qr/enum called with an array reference and additional arguments\. Did you mean to parenthesize the enum call's parameters\?/ );


done_testing;
