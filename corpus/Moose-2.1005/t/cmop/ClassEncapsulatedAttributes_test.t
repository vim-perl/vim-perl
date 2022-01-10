use strict;
use warnings;

use Test::More;
use File::Spec;

use Class::MOP;

BEGIN {
    require_ok(File::Spec->catfile('examples', 'ClassEncapsulatedAttributes.pod'));
}

{
    package Foo;

    use metaclass 'ClassEncapsulatedAttributes';

    Foo->meta->add_attribute('foo' => (
        accessor  => 'foo',
        predicate => 'has_foo',
        default   => 'init in FOO'
    ));

    Foo->meta->add_attribute('bar' => (
        reader  => 'get_bar',
        writer  => 'set_bar',
        default => 'init in FOO'
    ));

    sub new  {
        my $class = shift;
        $class->meta->new_object(@_);
    }

    package Bar;
    our @ISA = ('Foo');

    Bar->meta->add_attribute('foo' => (
        accessor  => 'foo',
        predicate => 'has_foo',
        default   => 'init in BAR'
    ));

    Bar->meta->add_attribute('bar' => (
        reader  => 'get_bar',
        writer  => 'set_bar',
        default => 'init in BAR'
    ));

    sub SUPER_foo     { (shift)->SUPER::foo(@_)     }
    sub SUPER_has_foo { (shift)->SUPER::foo(@_)     }
    sub SUPER_get_bar { (shift)->SUPER::get_bar()   }
    sub SUPER_set_bar { (shift)->SUPER::set_bar(@_) }

}

{
    my $foo = Foo->new();
    isa_ok($foo, 'Foo');

    can_ok($foo, 'foo');
    can_ok($foo, 'has_foo');
    can_ok($foo, 'get_bar');
    can_ok($foo, 'set_bar');

    my $bar = Bar->new();
    isa_ok($bar, 'Bar');

    can_ok($bar, 'foo');
    can_ok($bar, 'has_foo');
    can_ok($bar, 'get_bar');
    can_ok($bar, 'set_bar');

    ok($foo->has_foo, '... Foo::has_foo == 1');
    ok($bar->has_foo, '... Bar::has_foo == 1');

    is($foo->foo, 'init in FOO', '... got the right default value for Foo::foo');
    is($bar->foo, 'init in BAR', '... got the right default value for Bar::foo');

    is($bar->SUPER_foo(), 'init in FOO', '... got the right default value for Bar::SUPER::foo');

    $bar->SUPER_foo(undef);

    is($bar->SUPER_foo(), undef, '... successfully set Foo::foo through Bar::SUPER::foo');
    ok(!$bar->SUPER_has_foo, '... BAR::SUPER::has_foo == 0');

    ok($foo->has_foo, '... Foo::has_foo (is still) 1');
}

{
    my $bar = Bar->new(
        'Foo' => { 'foo' => 'Foo::foo' },
        'Bar' => { 'foo' => 'Bar::foo' }
    );
    isa_ok($bar, 'Bar');

    can_ok($bar, 'foo');
    can_ok($bar, 'has_foo');
    can_ok($bar, 'get_bar');
    can_ok($bar, 'set_bar');

    ok($bar->has_foo, '... Bar::has_foo == 1');
    ok($bar->SUPER_has_foo, '... Bar::SUPER_has_foo == 1');

    is($bar->foo, 'Bar::foo', '... got the right default value for Bar::foo');
    is($bar->SUPER_foo(), 'Foo::foo', '... got the right default value for Bar::SUPER::foo');
}

done_testing;
