use strict;
use warnings;

use FindBin;
use File::Spec::Functions;

use Test::More;
use Test::Fatal;

use Class::MOP;

use lib catdir($FindBin::Bin, 'lib');

# make sure the Class::MOP::Class->meta does the right thing

my $meta = Class::MOP::Class->meta();
isa_ok($meta, 'Class::MOP::Class');

my $new_meta = $meta->new_object('package' => 'Class::MOP::Class');
isa_ok($new_meta, 'Class::MOP::Class');
is($new_meta, $meta, '... it still creates the singleton');

my $cloned_meta = $meta->clone_object($meta);
isa_ok($cloned_meta, 'Class::MOP::Class');
is($cloned_meta, $meta, '... it creates the singleton even if you try to clone it');

# make sure other metaclasses do the right thing

{
    package Foo;
    use metaclass;
}

my $foo_meta = Foo->meta;
isa_ok($foo_meta, 'Class::MOP::Class');

is($meta->new_object('package' => 'Foo'), $foo_meta, '... got the right Foo->meta singleton');
is($meta->clone_object($foo_meta), $foo_meta, '... cloning got the right Foo->meta singleton');

# make sure subclassed of Class::MOP::Class do the right thing

my $my_meta = MyMetaClass->meta;
isa_ok($my_meta, 'Class::MOP::Class');

my $new_my_meta = $my_meta->new_object('package' => 'MyMetaClass');
isa_ok($new_my_meta, 'Class::MOP::Class');
is($new_my_meta, $my_meta, '... even subclasses still create the singleton');

my $cloned_my_meta = $meta->clone_object($my_meta);
isa_ok($cloned_my_meta, 'Class::MOP::Class');
is($cloned_my_meta, $my_meta, '... and subclasses creates the singleton even if you try to clone it');

is($my_meta->new_object('package' => 'Foo'), $foo_meta, '... got the right Foo->meta singleton (w/subclass)');
is($meta->clone_object($foo_meta), $foo_meta, '... cloning got the right Foo->meta singleton (w/subclass)');

# now create a metaclass for real

my $bar_meta = $my_meta->new_object('package' => 'Bar');
isa_ok($bar_meta, 'Class::MOP::Class');

is($bar_meta->name, 'Bar', '... got the right name for the Bar metaclass');
is($bar_meta->version, undef, '... Bar does not exists, so it has no version');

$bar_meta->superclasses('Foo');

# check with MyMetaClass

{
    package Baz;
    use metaclass 'MyMetaClass';
}

my $baz_meta = Baz->meta;
isa_ok($baz_meta, 'Class::MOP::Class');
isa_ok($baz_meta, 'MyMetaClass');

is($my_meta->new_object('package' => 'Baz'), $baz_meta, '... got the right Baz->meta singleton');
is($my_meta->clone_object($baz_meta), $baz_meta, '... cloning got the right Baz->meta singleton');

$baz_meta->superclasses('Bar');

# now create a regular objects for real

my $foo = $foo_meta->new_object();
isa_ok($foo, 'Foo');

my $bar = $bar_meta->new_object();
isa_ok($bar, 'Bar');
isa_ok($bar, 'Foo');

my $baz = $baz_meta->new_object();
isa_ok($baz, 'Baz');
isa_ok($baz, 'Bar');
isa_ok($baz, 'Foo');

my $cloned_foo = $foo_meta->clone_object($foo);
isa_ok($cloned_foo, 'Foo');

isnt($cloned_foo, $foo, '... $cloned_foo is a new object different from $foo');

# check some errors

isnt( exception {
    $foo_meta->clone_object($meta);
}, undef, '... this dies as expected' );

# test stuff

{
    package FooBar;
    use metaclass;

    FooBar->meta->add_attribute('test');
}

my $attr = FooBar->meta->get_attribute('test');
isa_ok($attr, 'Class::MOP::Attribute');

my $attr_clone = $attr->clone();
isa_ok($attr_clone, 'Class::MOP::Attribute');

isnt($attr, $attr_clone, '... we successfully cloned our attributes');
is($attr->associated_class,
   $attr_clone->associated_class,
   '... we successfully did not clone our associated metaclass');

done_testing;
