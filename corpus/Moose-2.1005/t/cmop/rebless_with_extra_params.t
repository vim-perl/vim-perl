use strict;
use warnings;

use Test::More;
use Test::Fatal;

use Class::MOP;

{
    package Foo;
    use metaclass;
    Foo->meta->add_attribute('bar' => (reader => 'bar'));

    sub new { (shift)->meta->new_object(@_) }

    package Bar;
    use metaclass;
    use base 'Foo';
    Bar->meta->add_attribute('baz' => (reader => 'baz', default => 'BAZ'));
}

# normal ...
{
    my $foo = Foo->new(bar => 'BAR');
    isa_ok($foo, 'Foo');

    is($foo->bar, 'BAR', '... got the expect value');
    ok(!$foo->can('baz'), '... no baz method though');

    is( exception {
        Bar->meta->rebless_instance($foo)
    }, undef, '... this works' );

    is($foo->bar, 'BAR', '... got the expect value');
    ok($foo->can('baz'), '... we have baz method now');
    is($foo->baz, 'BAZ', '... got the expect value');

    is( exception {
        Foo->meta->rebless_instance_back($foo)
    }, undef, '... this works' );
    is($foo->bar, 'BAR', '... got the expect value');
    ok(!$foo->can('baz'), '... no baz method though');
}

# with extra params ...
{
    my $foo = Foo->new(bar => 'BAR');
    isa_ok($foo, 'Foo');

    is($foo->bar, 'BAR', '... got the expect value');
    ok(!$foo->can('baz'), '... no baz method though');

    is( exception {
        Bar->meta->rebless_instance($foo, (baz => 'FOO-BAZ'))
    }, undef, '... this works' );

    is($foo->bar, 'BAR', '... got the expect value');
    ok($foo->can('baz'), '... we have baz method now');
    is($foo->baz, 'FOO-BAZ', '... got the expect value');

    is( exception {
        Foo->meta->rebless_instance_back($foo)
    }, undef, '... this works' );

    is($foo->bar, 'BAR', '... got the expect value');
    ok(!$foo->can('baz'), '... no baz method though');
    ok(!exists($foo->{baz}), '... and the baz attribute was deinitialized');
}

# with extra params ...
{
    my $foo = Foo->new(bar => 'BAR');
    isa_ok($foo, 'Foo');

    is($foo->bar, 'BAR', '... got the expect value');
    ok(!$foo->can('baz'), '... no baz method though');

    is( exception {
        Bar->meta->rebless_instance($foo, (bar => 'FOO-BAR', baz => 'FOO-BAZ'))
    }, undef, '... this works' );

    is($foo->bar, 'FOO-BAR', '... got the expect value');
    ok($foo->can('baz'), '... we have baz method now');
    is($foo->baz, 'FOO-BAZ', '... got the expect value');

    is( exception {
        Foo->meta->rebless_instance_back($foo)
    }, undef, '... this works' );

    is($foo->bar, 'FOO-BAR', '... got the expect value');
    ok(!$foo->can('baz'), '... no baz method though');
    ok(!exists($foo->{baz}), '... and the baz attribute was deinitialized');
}

done_testing;
