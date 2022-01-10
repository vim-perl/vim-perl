use strict;
use warnings;

use Test::More;
use Test::Fatal;

use Class::MOP;
use Class::MOP::Class;

=pod

The following class hierarhcy is very contrived
and totally horrid (it won't work under C3 even),
but it tests a number of aspect of this module.

A more real-world example would be a nice addition :)

=cut

{
    package Foo;

    sub BUILD { 'Foo::BUILD' }
    sub foo { 'Foo::foo' }

    package Bar;
    our @ISA = ('Foo');

    sub BUILD { 'Bar::BUILD' }
    sub bar { 'Bar::bar' }

    package Baz;
    our @ISA = ('Bar');

    sub baz { 'Baz::baz' }
    sub foo { 'Baz::foo' }

    package Foo::Bar;
    our @ISA = ('Foo', 'Bar');

    sub BUILD { 'Foo::Bar::BUILD' }
    sub foobar { 'Foo::Bar::foobar' }

    package Foo::Bar::Baz;
    our @ISA = ('Foo', 'Bar', 'Baz');

    sub BUILD { 'Foo::Bar::Baz::BUILD' }
    sub bar { 'Foo::Bar::Baz::bar' }
    sub foobarbaz { 'Foo::Bar::Baz::foobarbaz' }
}

ok(!defined(Class::MOP::Class->initialize('Foo')->find_next_method_by_name('BUILD')),
   '... Foo::BUILD has not next method');

is(Class::MOP::Class->initialize('Bar')->find_next_method_by_name('BUILD'),
   Class::MOP::Class->initialize('Foo')->get_method('BUILD'),
   '... Bar::BUILD does have a next method');

is(Class::MOP::Class->initialize('Baz')->find_next_method_by_name('BUILD'),
   Class::MOP::Class->initialize('Bar')->get_method('BUILD'),
   '... Baz->BUILD does have a next method');

is(Class::MOP::Class->initialize('Foo::Bar')->find_next_method_by_name('BUILD'),
   Class::MOP::Class->initialize('Foo')->get_method('BUILD'),
   '... Foo::Bar->BUILD does have a next method');

is(Class::MOP::Class->initialize('Foo::Bar::Baz')->find_next_method_by_name('BUILD'),
   Class::MOP::Class->initialize('Foo')->get_method('BUILD'),
   '... Foo::Bar::Baz->BUILD does have a next method');

is_deeply(
    [
        sort { $a->name cmp $b->name }
            grep { $_->package_name ne 'UNIVERSAL' }
            Class::MOP::Class->initialize('Foo')->get_all_methods()
    ],
    [
        Class::MOP::Class->initialize('Foo')->get_method('BUILD') ,
        Class::MOP::Class->initialize('Foo')->get_method('foo'),
    ],
    '... got the right list of applicable methods for Foo');

is_deeply(
    [
        sort { $a->name cmp $b->name }
            grep { $_->package_name ne 'UNIVERSAL' }
            Class::MOP::Class->initialize('Bar')->get_all_methods()
    ],
    [
        Class::MOP::Class->initialize('Bar')->get_method('BUILD'),
        Class::MOP::Class->initialize('Bar')->get_method('bar'),
        Class::MOP::Class->initialize('Foo')->get_method('foo'),
    ],
    '... got the right list of applicable methods for Bar');


is_deeply(
    [
        sort { $a->name cmp $b->name }
            grep { $_->package_name ne 'UNIVERSAL' }
            Class::MOP::Class->initialize('Baz')->get_all_methods()
    ],
    [
        Class::MOP::Class->initialize('Bar')->get_method('BUILD'),
        Class::MOP::Class->initialize('Bar')->get_method('bar'),
        Class::MOP::Class->initialize('Baz')->get_method('baz'),
        Class::MOP::Class->initialize('Baz')->get_method('foo'),
    ],
    '... got the right list of applicable methods for Baz');

is_deeply(
    [
        sort { $a->name cmp $b->name }
            grep { $_->package_name ne 'UNIVERSAL' }
            Class::MOP::Class->initialize('Foo::Bar')->get_all_methods()
    ],
    [
        Class::MOP::Class->initialize('Foo::Bar')->get_method('BUILD'),
        Class::MOP::Class->initialize('Bar')->get_method('bar'),
        Class::MOP::Class->initialize('Foo')->get_method('foo'),
        Class::MOP::Class->initialize('Foo::Bar')->get_method('foobar'),
    ],
    '... got the right list of applicable methods for Foo::Bar');

## find_all_methods_by_name

is_deeply(
    [ Class::MOP::Class->initialize('Foo::Bar')->find_all_methods_by_name('BUILD') ],
    [
        {
            name  => 'BUILD',
            class => 'Foo::Bar',
            code  => Class::MOP::Class->initialize('Foo::Bar')->get_method('BUILD')
        },
        {
            name  => 'BUILD',
            class => 'Foo',
            code  => Class::MOP::Class->initialize('Foo')->get_method('BUILD')
        },
        {
            name  => 'BUILD',
            class => 'Bar',
            code  => Class::MOP::Class->initialize('Bar')->get_method('BUILD')
        }
    ],
    '... got the right list of BUILD methods for Foo::Bar');

is_deeply(
    [ Class::MOP::Class->initialize('Foo::Bar::Baz')->find_all_methods_by_name('BUILD') ],
    [
        {
            name  => 'BUILD',
            class => 'Foo::Bar::Baz',
            code  => Class::MOP::Class->initialize('Foo::Bar::Baz')->get_method('BUILD')
        },
        {
            name  => 'BUILD',
            class => 'Foo',
            code  => Class::MOP::Class->initialize('Foo')->get_method('BUILD')
        },
        {
            name  => 'BUILD',
            class => 'Bar',
            code  => Class::MOP::Class->initialize('Bar')->get_method('BUILD')
        },
    ],
    '... got the right list of BUILD methods for Foo::Bar::Baz');

done_testing;
