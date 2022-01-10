use strict;
use warnings;

use Test::More;
use Test::Fatal;
use Moose::Util qw( add_method_modifier );

my $COUNT = 0;
{
    package Foo;
    use Moose;

    sub foo { }
    sub bar { }
}

is( exception {
    add_method_modifier('Foo', 'before', [ ['foo', 'bar'], sub { $COUNT++ } ]);
}, undef, 'method modifier with an arrayref' );

isnt( exception {
    add_method_modifier('Foo', 'before', [ {'foo' => 'bar'}, sub { $COUNT++ } ]);
}, undef, 'method modifier with a hashref' );

my $foo = Foo->new;
$foo->foo;
$foo->bar;
is($COUNT, 2, "checking that the modifiers were installed.");


done_testing;
