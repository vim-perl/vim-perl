#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;


# -------------------------------------------------------------------
# HASH handles
# -------------------------------------------------------------------
# the canonical form of of the 'handles'
# option is the hash ref mapping a
# method name to the delegated method name

{
    package Foo;
    use Moose;

    has 'bar' => (is => 'rw', default => 10);

    sub baz { 42 }

    package Bar;
    use Moose;

    has 'foo' => (
        is      => 'rw',
        default => sub { Foo->new },
        handles => {
            'foo_bar' => 'bar',
            foo_baz => 'baz',
            'foo_bar_to_20' => [ bar => 20 ],
        },
    );
}

my $bar = Bar->new;
isa_ok($bar, 'Bar');

ok($bar->foo, '... we have something in bar->foo');
isa_ok($bar->foo, 'Foo');

my $meth = Bar->meta->get_method('foo_bar');
isa_ok($meth, 'Moose::Meta::Method::Delegation');
is($meth->associated_attribute->name, 'foo',
   'associated_attribute->name for this method is foo');

is($bar->foo->bar, 10, '... bar->foo->bar returned the right default');

can_ok($bar, 'foo_bar');
is($bar->foo_bar, 10, '... bar->foo_bar delegated correctly');

# change the value ...

$bar->foo->bar(30);

# and make sure the delegation picks it up

is($bar->foo->bar, 30, '... bar->foo->bar returned the right (changed) value');
is($bar->foo_bar, 30, '... bar->foo_bar delegated correctly');

# change the value through the delegation ...

$bar->foo_bar(50);

# and make sure everyone sees it

is($bar->foo->bar, 50, '... bar->foo->bar returned the right (changed) value');
is($bar->foo_bar, 50, '... bar->foo_bar delegated correctly');

# change the object we are delegating too

my $foo = Foo->new(bar => 25);
isa_ok($foo, 'Foo');

is($foo->bar, 25, '... got the right foo->bar');

is( exception {
    $bar->foo($foo);
}, undef, '... assigned the new Foo to Bar->foo' );

is($bar->foo, $foo, '... assigned bar->foo with the new Foo');

is($bar->foo->bar, 25, '... bar->foo->bar returned the right result');
is($bar->foo_bar, 25, '... and bar->foo_bar delegated correctly again');

# curried handles
$bar->foo_bar_to_20;
is($bar->foo_bar, 20, '... correctly curried a single argument');

# -------------------------------------------------------------------
# ARRAY handles
# -------------------------------------------------------------------
# we also support an array based format
# which assumes that the name is the same
# on either end

{
    package Engine;
    use Moose;

    sub go   { 'Engine::go'   }
    sub stop { 'Engine::stop' }

    package Car;
    use Moose;

    has 'engine' => (
        is      => 'rw',
        default => sub { Engine->new },
        handles => [ 'go', 'stop' ]
    );
}

my $car = Car->new;
isa_ok($car, 'Car');

isa_ok($car->engine, 'Engine');
can_ok($car->engine, 'go');
can_ok($car->engine, 'stop');

is($car->engine->go, 'Engine::go', '... got the right value from ->engine->go');
is($car->engine->stop, 'Engine::stop', '... got the right value from ->engine->stop');

can_ok($car, 'go');
can_ok($car, 'stop');

is($car->go, 'Engine::go', '... got the right value from ->go');
is($car->stop, 'Engine::stop', '... got the right value from ->stop');

# -------------------------------------------------------------------
# REGEXP handles
# -------------------------------------------------------------------
# and we support regexp delegation

{
    package Baz;
    use Moose;

    sub foo { 'Baz::foo' }
    sub bar { 'Baz::bar' }
    sub boo { 'Baz::boo' }

    package Baz::Proxy1;
    use Moose;

    has 'baz' => (
        is      => 'ro',
        isa     => 'Baz',
        default => sub { Baz->new },
        handles => qr/.*/
    );

    package Baz::Proxy2;
    use Moose;

    has 'baz' => (
        is      => 'ro',
        isa     => 'Baz',
        default => sub { Baz->new },
        handles => qr/.oo/
    );

    package Baz::Proxy3;
    use Moose;

    has 'baz' => (
        is      => 'ro',
        isa     => 'Baz',
        default => sub { Baz->new },
        handles => qr/b.*/
    );
}

{
    my $baz_proxy = Baz::Proxy1->new;
    isa_ok($baz_proxy, 'Baz::Proxy1');

    can_ok($baz_proxy, 'baz');
    isa_ok($baz_proxy->baz, 'Baz');

    can_ok($baz_proxy, 'foo');
    can_ok($baz_proxy, 'bar');
    can_ok($baz_proxy, 'boo');

    is($baz_proxy->foo, 'Baz::foo', '... got the right proxied return value');
    is($baz_proxy->bar, 'Baz::bar', '... got the right proxied return value');
    is($baz_proxy->boo, 'Baz::boo', '... got the right proxied return value');
}
{
    my $baz_proxy = Baz::Proxy2->new;
    isa_ok($baz_proxy, 'Baz::Proxy2');

    can_ok($baz_proxy, 'baz');
    isa_ok($baz_proxy->baz, 'Baz');

    can_ok($baz_proxy, 'foo');
    can_ok($baz_proxy, 'boo');

    is($baz_proxy->foo, 'Baz::foo', '... got the right proxied return value');
    is($baz_proxy->boo, 'Baz::boo', '... got the right proxied return value');
}
{
    my $baz_proxy = Baz::Proxy3->new;
    isa_ok($baz_proxy, 'Baz::Proxy3');

    can_ok($baz_proxy, 'baz');
    isa_ok($baz_proxy->baz, 'Baz');

    can_ok($baz_proxy, 'bar');
    can_ok($baz_proxy, 'boo');

    is($baz_proxy->bar, 'Baz::bar', '... got the right proxied return value');
    is($baz_proxy->boo, 'Baz::boo', '... got the right proxied return value');
}

# -------------------------------------------------------------------
# ROLE handles
# -------------------------------------------------------------------

{
    package Foo::Bar;
    use Moose::Role;

    requires 'foo';
    requires 'bar';

    package Foo::Baz;
    use Moose;

    sub foo { 'Foo::Baz::FOO' }
    sub bar { 'Foo::Baz::BAR' }
    sub baz { 'Foo::Baz::BAZ' }

    package Foo::Thing;
    use Moose;

    has 'thing' => (
        is      => 'rw',
        isa     => 'Foo::Baz',
        handles => 'Foo::Bar',
    );

    package Foo::OtherThing;
    use Moose;
    use Moose::Util::TypeConstraints;

    has 'other_thing' => (
        is      => 'rw',
        isa     => 'Foo::Baz',
        handles => Moose::Util::TypeConstraints::find_type_constraint('Foo::Bar'),
    );
}

{
    my $foo = Foo::Thing->new(thing => Foo::Baz->new);
    isa_ok($foo, 'Foo::Thing');
    isa_ok($foo->thing, 'Foo::Baz');

    ok($foo->meta->has_method('foo'), '... we have the method we expect');
    ok($foo->meta->has_method('bar'), '... we have the method we expect');
    ok(!$foo->meta->has_method('baz'), '... we dont have the method we expect');

    is($foo->foo, 'Foo::Baz::FOO', '... got the right value');
    is($foo->bar, 'Foo::Baz::BAR', '... got the right value');
    is($foo->thing->baz, 'Foo::Baz::BAZ', '... got the right value');
}

{
    my $foo = Foo::OtherThing->new(other_thing => Foo::Baz->new);
    isa_ok($foo, 'Foo::OtherThing');
    isa_ok($foo->other_thing, 'Foo::Baz');

    ok($foo->meta->has_method('foo'), '... we have the method we expect');
    ok($foo->meta->has_method('bar'), '... we have the method we expect');
    ok(!$foo->meta->has_method('baz'), '... we dont have the method we expect');

    is($foo->foo, 'Foo::Baz::FOO', '... got the right value');
    is($foo->bar, 'Foo::Baz::BAR', '... got the right value');
    is($foo->other_thing->baz, 'Foo::Baz::BAZ', '... got the right value');
}
# -------------------------------------------------------------------
# AUTOLOAD & handles
# -------------------------------------------------------------------

{
    package Foo::Autoloaded;
    use Moose;

    sub AUTOLOAD {
        my $self = shift;

        my $name = our $AUTOLOAD;
        $name =~ s/.*://; # strip fully-qualified portion

        if (@_) {
            return $self->{$name} = shift;
        } else {
            return $self->{$name};
        }
    }

    package Bar::Autoloaded;
    use Moose;

    has 'foo' => (
        is      => 'rw',
        default => sub { Foo::Autoloaded->new },
        handles => { 'foo_bar' => 'bar' }
    );

    package Baz::Autoloaded;
    use Moose;

    has 'foo' => (
        is      => 'rw',
        default => sub { Foo::Autoloaded->new },
        handles => ['bar']
    );

    package Goorch::Autoloaded;
    use Moose;

    ::isnt( ::exception {
        has 'foo' => (
            is      => 'rw',
            default => sub { Foo::Autoloaded->new },
            handles => qr/bar/
        );
    }, undef, '... you cannot delegate to AUTOLOADED class with regexp' );
}

# check HASH based delegation w/ AUTOLOAD

{
    my $bar = Bar::Autoloaded->new;
    isa_ok($bar, 'Bar::Autoloaded');

    ok($bar->foo, '... we have something in bar->foo');
    isa_ok($bar->foo, 'Foo::Autoloaded');

    # change the value ...

    $bar->foo->bar(30);

    # and make sure the delegation picks it up

    is($bar->foo->bar, 30, '... bar->foo->bar returned the right (changed) value');
    is($bar->foo_bar, 30, '... bar->foo_bar delegated correctly');

    # change the value through the delegation ...

    $bar->foo_bar(50);

    # and make sure everyone sees it

    is($bar->foo->bar, 50, '... bar->foo->bar returned the right (changed) value');
    is($bar->foo_bar, 50, '... bar->foo_bar delegated correctly');

    # change the object we are delegating too

    my $foo = Foo::Autoloaded->new;
    isa_ok($foo, 'Foo::Autoloaded');

    $foo->bar(25);

    is($foo->bar, 25, '... got the right foo->bar');

    is( exception {
        $bar->foo($foo);
    }, undef, '... assigned the new Foo to Bar->foo' );

    is($bar->foo, $foo, '... assigned bar->foo with the new Foo');

    is($bar->foo->bar, 25, '... bar->foo->bar returned the right result');
    is($bar->foo_bar, 25, '... and bar->foo_bar delegated correctly again');
}

# check ARRAY based delegation w/ AUTOLOAD

{
    my $baz = Baz::Autoloaded->new;
    isa_ok($baz, 'Baz::Autoloaded');

    ok($baz->foo, '... we have something in baz->foo');
    isa_ok($baz->foo, 'Foo::Autoloaded');

    # change the value ...

    $baz->foo->bar(30);

    # and make sure the delegation picks it up

    is($baz->foo->bar, 30, '... baz->foo->bar returned the right (changed) value');
    is($baz->bar, 30, '... baz->foo_bar delegated correctly');

    # change the value through the delegation ...

    $baz->bar(50);

    # and make sure everyone sees it

    is($baz->foo->bar, 50, '... baz->foo->bar returned the right (changed) value');
    is($baz->bar, 50, '... baz->foo_bar delegated correctly');

    # change the object we are delegating too

    my $foo = Foo::Autoloaded->new;
    isa_ok($foo, 'Foo::Autoloaded');

    $foo->bar(25);

    is($foo->bar, 25, '... got the right foo->bar');

    is( exception {
        $baz->foo($foo);
    }, undef, '... assigned the new Foo to Baz->foo' );

    is($baz->foo, $foo, '... assigned baz->foo with the new Foo');

    is($baz->foo->bar, 25, '... baz->foo->bar returned the right result');
    is($baz->bar, 25, '... and baz->foo_bar delegated correctly again');
}

# Check that removing attributes removes their handles methods also.
{
    {
        package Quux;
        use Moose;
        has foo => (
            isa => 'Foo',
            default => sub { Foo->new },
            handles => { 'foo_bar' => 'bar' }
        );
    }
    my $i = Quux->new;
    ok($i->meta->has_method('foo_bar'), 'handles method foo_bar is present');
    $i->meta->remove_attribute('foo');
    ok(!$i->meta->has_method('foo_bar'), 'handles method foo_bar is removed');
}

# Make sure that a useful error message is thrown when the delegation target is
# not an object
{
    my $i = Bar->new(foo => undef);
    like( exception { $i->foo_bar }, qr/is not defined/, 'useful error from unblessed reference' );

    my $j = Bar->new(foo => []);
    like( exception { $j->foo_bar }, qr/is not an object \(got 'ARRAY/, 'useful error from unblessed reference' );

    my $k = Bar->new(foo => "Foo");
    is( exception { $k->foo_baz }, undef, "but not for class name" );
}

{
    package Delegator;
    use Moose;

    sub full { 1 }
    sub stub;

    ::like(
        ::exception{ has d1 => (
                isa     => 'X',
                handles => ['full'],
            );
            },
        qr/\QYou cannot overwrite a locally defined method (full) with a delegation/,
        'got an error when trying to declare a delegation method that overwrites a local method'
    );

    ::is(
        ::exception{ has d2 => (
                isa     => 'X',
                handles => ['stub'],
            );
            },
        undef,
        'no error when trying to declare a delegation method that overwrites a stub method'
    );
}

done_testing;
