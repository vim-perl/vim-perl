use strict;
use warnings;

use Test::More;

use Class::MOP;

=pod

This tests a bug sent via RT #27329

=cut

{
    package Foo;
    use metaclass;

    Foo->meta->add_attribute('foo' => (
        init_arg => 'foo',
        reader   => 'get_foo',
        default  => 'BAR',
    ));

}

my $foo = Foo->meta->new_object;
isa_ok($foo, 'Foo');

is($foo->get_foo, 'BAR', '... got the right default value');

{
    my $clone = $foo->meta->clone_object($foo, foo => 'BAZ');
    isa_ok($clone, 'Foo');
    isnt($clone, $foo, '... and it is a clone');

    is($clone->get_foo, 'BAZ', '... got the right cloned value');
}

{
    my $clone = $foo->meta->clone_object($foo, foo => undef);
    isa_ok($clone, 'Foo');
    isnt($clone, $foo, '... and it is a clone');

    ok(!defined($clone->get_foo), '... got the right cloned value');
}

done_testing;
