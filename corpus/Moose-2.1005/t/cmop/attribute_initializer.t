use strict;
use warnings;

use Scalar::Util 'blessed', 'reftype';

use Test::More;

use Class::MOP;

=pod

This checks that the initializer is used to set the initial value.

=cut

{
    package Foo;
    use metaclass;

    Foo->meta->add_attribute('bar' =>
        reader      => 'get_bar',
        writer      => 'set_bar',
        initializer => sub {
            my ($self, $value, $callback, $attr) = @_;

            ::isa_ok($attr, 'Class::MOP::Attribute');
            ::is($attr->name, 'bar', '... the attribute is our own');

            $callback->($value * 2);
        },
    );
}

can_ok('Foo', 'get_bar');
can_ok('Foo', 'set_bar');

my $foo = Foo->meta->new_object(bar => 10);
is($foo->get_bar, 20, "... initial argument was doubled as expected");

$foo->set_bar(30);

is($foo->get_bar, 30, "... and setter works correctly");

# meta tests ...

my $bar = Foo->meta->get_attribute('bar');
isa_ok($bar, 'Class::MOP::Attribute');

ok($bar->has_initializer, '... bar has an initializer');
is(reftype $bar->initializer, 'CODE', '... the initializer is a CODE ref');

done_testing;
