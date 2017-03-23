use strict;
use warnings;

use Test::More;
use Test::Fatal;
use Scalar::Util 'blessed';

{
        package Parent;
        use metaclass;

        sub new    { bless {} => shift }
        sub whoami { "parent"          }
        sub parent { "parent"          }

        package Child;
        use metaclass;
        use base qw/Parent/;

        sub whoami { "child" }
        sub child  { "child" }

        package LeftField;
        use metaclass;

        sub new    { bless {} => shift }
        sub whoami { "leftfield"       }
        sub myhax  { "areleet"         }
}

# basic tests
my $foo = Parent->new;
is(blessed($foo), 'Parent', 'Parent->new gives a Parent');
is($foo->whoami, "parent", 'Parent->whoami gives parent');
is($foo->parent, "parent", 'Parent->parent gives parent');
isnt( exception { $foo->child }, undef, "Parent->child method doesn't exist" );

Child->meta->rebless_instance($foo);
is(blessed($foo), 'Child', 'rebless_instance really reblessed the instance');
is($foo->whoami, "child", 'reblessed->whoami gives child');
is($foo->parent, "parent", 'reblessed->parent gives parent');
is($foo->child, "child", 'reblessed->child gives child');

like( exception { LeftField->meta->rebless_instance($foo) }, qr/You may rebless only into a subclass of \(Child\), of which \(LeftField\) isn't\./ );

like( exception { Class::MOP::Class->initialize("NonExistent")->rebless_instance($foo) }, qr/You may rebless only into a subclass of \(Child\), of which \(NonExistent\) isn't\./ );

Parent->meta->rebless_instance_back($foo);
is(blessed($foo), 'Parent', 'Parent->new gives a Parent');
is($foo->whoami, "parent", 'Parent->whoami gives parent');
is($foo->parent, "parent", 'Parent->parent gives parent');
isnt( exception { $foo->child }, undef, "Parent->child method doesn't exist" );

like( exception { LeftField->meta->rebless_instance_back($foo) }, qr/You may rebless only into a superclass of \(Parent\), of which \(LeftField\) isn't\./ );

like( exception { Class::MOP::Class->initialize("NonExistent")->rebless_instance_back($foo) }, qr/You may rebless only into a superclass of \(Parent\), of which \(NonExistent\) isn't\./ );

# make sure our ->meta is still sane
my $bar = Parent->new;
is(blessed($bar), 'Parent', "sanity check");
is(blessed($bar->meta), 'Class::MOP::Class', "meta gives a Class::MOP::Class");
is($bar->meta->name, 'Parent', "this Class::MOP::Class instance is for Parent");

ok($bar->meta->has_method('new'), 'metaclass has "new" method');
ok($bar->meta->has_method('whoami'), 'metaclass has "whoami" method');
ok($bar->meta->has_method('parent'), 'metaclass has "parent" method');

is(blessed($bar->meta->new_object), 'Parent', 'new_object gives a Parent');

Child->meta->rebless_instance($bar);
is(blessed($bar), 'Child', "rebless really reblessed");
is(blessed($bar->meta), 'Class::MOP::Class', "meta gives a Class::MOP::Class");
is($bar->meta->name, 'Child', "this Class::MOP::Class instance is for Child");

ok($bar->meta->find_method_by_name('new'), 'metaclass has "new" method');
ok($bar->meta->find_method_by_name('parent'), 'metaclass has "parent" method');
ok(!$bar->meta->has_method('new'), 'no "new" method in this class');
ok(!$bar->meta->has_method('parent'), 'no "parent" method in this class');
ok($bar->meta->has_method('whoami'), 'metaclass has "whoami" method');
ok($bar->meta->has_method('child'), 'metaclass has "child" method');

is(blessed($bar->meta->new_object), 'Child', 'new_object gives a Child');

Parent->meta->rebless_instance_back($bar);
is(blessed($bar), 'Parent', "sanity check");
is(blessed($bar->meta), 'Class::MOP::Class', "meta gives a Class::MOP::Class");
is($bar->meta->name, 'Parent', "this Class::MOP::Class instance is for Parent");

ok($bar->meta->has_method('new'), 'metaclass has "new" method');
ok($bar->meta->has_method('whoami'), 'metaclass has "whoami" method');
ok($bar->meta->has_method('parent'), 'metaclass has "parent" method');

is(blessed($bar->meta->new_object), 'Parent', 'new_object gives a Parent');

done_testing;
