use strict;
use warnings;

use Test::More;
use File::Spec;

use Class::MOP;

BEGIN {
    require_ok(File::Spec->catfile('examples', 'AttributesWithHistory.pod'));
}

{
    package Foo;
    use metaclass;

    Foo->meta->add_attribute(AttributesWithHistory->new('foo' => (
        accessor         => 'foo',
        history_accessor => 'get_foo_history',
    )));

    Foo->meta->add_attribute(AttributesWithHistory->new('bar' => (
        reader           => 'get_bar',
        writer           => 'set_bar',
        history_accessor => 'get_bar_history',
    )));

    sub new  {
        my $class = shift;
        $class->meta->new_object(@_);
    }
}

my $foo = Foo->new();
isa_ok($foo, 'Foo');

can_ok($foo, 'foo');
can_ok($foo, 'get_foo_history');
can_ok($foo, 'set_bar');
can_ok($foo, 'get_bar');
can_ok($foo, 'get_bar_history');

my $foo2 = Foo->new();
isa_ok($foo2, 'Foo');

is($foo->foo, undef, '... foo is not yet defined');
is_deeply(
    [ $foo->get_foo_history() ],
    [ ],
    '... got correct empty history for foo');

is($foo2->foo, undef, '... foo2 is not yet defined');
is_deeply(
    [ $foo2->get_foo_history() ],
    [ ],
    '... got correct empty history for foo2');

$foo->foo(42);
is($foo->foo, 42, '... foo == 42');
is_deeply(
    [ $foo->get_foo_history() ],
    [ 42 ],
    '... got correct history for foo');

is($foo2->foo, undef, '... foo2 is still not yet defined');
is_deeply(
    [ $foo2->get_foo_history() ],
    [ ],
    '... still got correct empty history for foo2');

$foo2->foo(100);
is($foo->foo, 42, '... foo is still == 42');
is_deeply(
    [ $foo->get_foo_history() ],
    [ 42 ],
    '... still got correct history for foo');

is($foo2->foo, 100, '... foo2 == 100');
is_deeply(
    [ $foo2->get_foo_history() ],
    [ 100 ],
    '... got correct empty history for foo2');

$foo->foo(43);
$foo->foo(44);
$foo->foo(45);
$foo->foo(46);

is_deeply(
    [ $foo->get_foo_history() ],
    [ 42, 43, 44, 45, 46 ],
    '... got correct history for foo');

is($foo->get_bar, undef, '... bar is not yet defined');
is_deeply(
    [ $foo->get_bar_history() ],
    [ ],
    '... got correct empty history for foo');


$foo->set_bar("FOO");
is($foo->get_bar, "FOO", '... bar == "FOO"');
is_deeply(
    [ $foo->get_bar_history() ],
    [ "FOO" ],
    '... got correct history for foo');

$foo->set_bar("BAR");
$foo->set_bar("BAZ");

is_deeply(
    [ $foo->get_bar_history() ],
    [ qw/FOO BAR BAZ/ ],
    '... got correct history for bar');

is_deeply(
    [ $foo->get_foo_history() ],
    [ 42, 43, 44, 45, 46 ],
    '... still have the correct history for foo');

done_testing;
