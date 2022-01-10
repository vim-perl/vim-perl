use strict;
use warnings;

use Test::More;
use Test::Fatal;

use Class::MOP;
use Class::MOP::Class;

{
    package Foo;
    use metaclass;
    our $VERSION = '0.01';

    package Bar;
    our @ISA = ('Foo');

    our $AUTHORITY = 'cpan:JRANDOM';
}

my $Foo = Foo->meta;
isa_ok($Foo, 'Class::MOP::Class');

my $Bar = Bar->meta;
isa_ok($Bar, 'Class::MOP::Class');

is($Foo->name, 'Foo', '... Foo->name == Foo');
is($Bar->name, 'Bar', '... Bar->name == Bar');

is($Foo->version, '0.01', '... Foo->version == 0.01');
is($Bar->version, undef, '... Bar->version == undef');

is($Foo->authority, undef, '... Foo->authority == undef');
is($Bar->authority, 'cpan:JRANDOM', '... Bar->authority == cpan:JRANDOM');

is($Foo->identifier, 'Foo-0.01', '... Foo->identifier == Foo-0.01');
is($Bar->identifier, 'Bar-cpan:JRANDOM', '... Bar->identifier == Bar-cpan:JRANDOM');

is_deeply([$Foo->superclasses], [], '... Foo has no superclasses');
is_deeply([$Bar->superclasses], ['Foo'], '... Bar->superclasses == (Foo)');

$Foo->superclasses('UNIVERSAL');

is_deeply([$Foo->superclasses], ['UNIVERSAL'], '... Foo->superclasses == (UNIVERSAL) now');

is_deeply(
    [ $Foo->class_precedence_list ],
    [ 'Foo', 'UNIVERSAL' ],
    '... Foo->class_precedence_list == (Foo, UNIVERSAL)');

is_deeply(
    [ $Bar->class_precedence_list ],
    [ 'Bar', 'Foo', 'UNIVERSAL' ],
    '... Bar->class_precedence_list == (Bar, Foo, UNIVERSAL)');

# create a class using Class::MOP::Class ...

my $Baz = Class::MOP::Class->create(
            'Baz' => (
                version      => '0.10',
                authority    => 'cpan:YOMAMA',
                superclasses => [ 'Bar' ]
            ));
isa_ok($Baz, 'Class::MOP::Class');
is(Baz->meta, $Baz, '... our metaclasses are singletons');

is($Baz->name, 'Baz', '... Baz->name == Baz');
is($Baz->version, '0.10', '... Baz->version == 0.10');
is($Baz->authority, 'cpan:YOMAMA', '... Baz->authority == YOMAMA');

is($Baz->identifier, 'Baz-0.10-cpan:YOMAMA', '... Baz->identifier == Baz-0.10-cpan:YOMAMA');

is_deeply([$Baz->superclasses], ['Bar'], '... Baz->superclasses == (Bar)');

is_deeply(
    [ $Baz->class_precedence_list ],
    [ 'Baz', 'Bar', 'Foo', 'UNIVERSAL' ],
    '... Baz->class_precedence_list == (Baz, Bar, Foo, UNIVERSAL)');

done_testing;
