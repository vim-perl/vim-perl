use strict;
use warnings;

use Test::More;

use metaclass;

# meta classes
{
    package Foo::Meta::Instance;
    use base 'Class::MOP::Instance';

    package Bar::Meta::Instance;
    use base 'Class::MOP::Instance';

    package FooBar::Meta::Instance;
    use base 'Foo::Meta::Instance', 'Bar::Meta::Instance';
}

$@ = undef;
eval {
    package Foo;
    metaclass->import('instance_metaclass' => 'Foo::Meta::Instance');
};
ok(!$@, '... Foo.meta => Foo::Meta is compatible') || diag $@;

$@ = undef;
eval {
    package Bar;
    metaclass->import('instance_metaclass' => 'Bar::Meta::Instance');
};
ok(!$@, '... Bar.meta => Bar::Meta is compatible') || diag $@;

$@ = undef;
eval {
    package Foo::Foo;
    metaclass->import('instance_metaclass' => 'Bar::Meta::Instance');
    Foo::Foo->meta->superclasses('Foo');
};
ok($@, '... Foo::Foo.meta => Bar::Meta is not compatible') || diag $@;

$@ = undef;
eval {
    package Bar::Bar;
    metaclass->import('instance_metaclass' => 'Foo::Meta::Instance');
    Bar::Bar->meta->superclasses('Bar');
};
ok($@, '... Bar::Bar.meta => Foo::Meta is not compatible') || diag $@;

$@ = undef;
eval {
    package FooBar;
    metaclass->import('instance_metaclass' => 'FooBar::Meta::Instance');
    FooBar->meta->superclasses('Foo');
};
ok(!$@, '... FooBar.meta => FooBar::Meta is compatible') || diag $@;

$@ = undef;
eval {
    package FooBar2;
    metaclass->import('instance_metaclass' => 'FooBar::Meta::Instance');
    FooBar2->meta->superclasses('Bar');
};
ok(!$@, '... FooBar2.meta => FooBar::Meta is compatible') || diag $@;

done_testing;
