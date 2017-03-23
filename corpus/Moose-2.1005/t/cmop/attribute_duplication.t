use strict;
use warnings;

use Scalar::Util;

use Test::More;

use Class::MOP;

=pod

This tests that when an attribute of the same name
is added to a class, that it will remove the old
one first.

=cut

{
    package Foo;
    use metaclass;

    Foo->meta->add_attribute('bar' =>
        reader => 'get_bar',
        writer => 'set_bar',
    );

    ::can_ok('Foo', 'get_bar');
    ::can_ok('Foo', 'set_bar');
    ::ok(Foo->meta->has_attribute('bar'), '... Foo has the attribute bar');

    my $bar_attr = Foo->meta->get_attribute('bar');

    ::is($bar_attr->reader, 'get_bar', '... the bar attribute has the reader get_bar');
    ::is($bar_attr->writer, 'set_bar', '... the bar attribute has the writer set_bar');
    ::is($bar_attr->associated_class, Foo->meta, '... and the bar attribute is associated with Foo->meta');

    Foo->meta->add_attribute('bar' =>
        reader => 'assign_bar'
    );

    ::ok(!Foo->can('get_bar'), '... Foo no longer has the get_bar method');
    ::ok(!Foo->can('set_bar'), '... Foo no longer has the set_bar method');
    ::can_ok('Foo', 'assign_bar');
    ::ok(Foo->meta->has_attribute('bar'), '... Foo still has the attribute bar');

    my $bar_attr2 = Foo->meta->get_attribute('bar');

    ::isnt($bar_attr, $bar_attr2, '... this is a new bar attribute');
    ::isnt($bar_attr->associated_class, Foo->meta, '... and the old bar attribute is no longer associated with Foo->meta');

    ::is($bar_attr2->associated_class, Foo->meta, '... and the new bar attribute *is* associated with Foo->meta');

    ::isnt($bar_attr2->reader, 'get_bar', '... the bar attribute no longer has the reader get_bar');
    ::isnt($bar_attr2->reader, 'set_bar', '... the bar attribute no longer has the reader set_bar');
    ::is($bar_attr2->reader, 'assign_bar', '... the bar attribute now has the reader assign_bar');
}

done_testing;
