use strict;
use warnings;

use Test::More;

use metaclass;

# meta classes
{
    package Foo::Meta;
    use base 'Class::MOP::Class';

    package Bar::Meta;
    use base 'Class::MOP::Class';

    package FooBar::Meta;
    use base 'Foo::Meta', 'Bar::Meta';
}

$@ = undef;
eval {
    package Foo;
    metaclass->import('Foo::Meta');
};
ok(!$@, '... Foo.meta => Foo::Meta is compatible') || diag $@;

$@ = undef;
eval {
    package Bar;
    metaclass->import('Bar::Meta');
};
ok(!$@, '... Bar.meta => Bar::Meta is compatible') || diag $@;

$@ = undef;
eval {
    package Foo::Foo;
    metaclass->import('Bar::Meta');
    Foo::Foo->meta->superclasses('Foo');
};
ok($@, '... Foo::Foo.meta => Bar::Meta is not compatible') || diag $@;

$@ = undef;
eval {
    package Bar::Bar;
    metaclass->import('Foo::Meta');
    Bar::Bar->meta->superclasses('Bar');
};
ok($@, '... Bar::Bar.meta => Foo::Meta is not compatible') || diag $@;

$@ = undef;
eval {
    package FooBar;
    metaclass->import('FooBar::Meta');
    FooBar->meta->superclasses('Foo');
};
ok(!$@, '... FooBar.meta => FooBar::Meta is compatible') || diag $@;

$@ = undef;
eval {
    package FooBar2;
    metaclass->import('FooBar::Meta');
    FooBar2->meta->superclasses('Bar');
};
ok(!$@, '... FooBar2.meta => FooBar::Meta is compatible') || diag $@;

done_testing;
