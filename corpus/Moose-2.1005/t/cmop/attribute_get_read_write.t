use strict;
use warnings;

use Scalar::Util 'blessed', 'reftype';

use Test::More;

use Class::MOP;

=pod

This checks the get_read/write_method
and get_read/write_method_ref methods

=cut

{
    package Foo;
    use metaclass;

    Foo->meta->add_attribute('bar' =>
        reader => 'get_bar',
        writer => 'set_bar',
    );

    Foo->meta->add_attribute('baz' =>
        accessor => 'baz',
    );

    Foo->meta->add_attribute('gorch' =>
        reader => { 'get_gorch', => sub { (shift)->{gorch} } }
    );

    package Bar;
    use metaclass;
    Bar->meta->superclasses('Foo');

    Bar->meta->add_attribute('quux' =>
        accessor => 'quux',
    );
}

can_ok('Foo', 'get_bar');
can_ok('Foo', 'set_bar');
can_ok('Foo', 'baz');
can_ok('Foo', 'get_gorch');

ok(Foo->meta->has_attribute('bar'), '... Foo has the attribute bar');
ok(Foo->meta->has_attribute('baz'), '... Foo has the attribute baz');
ok(Foo->meta->has_attribute('gorch'), '... Foo has the attribute gorch');

my $bar_attr = Foo->meta->get_attribute('bar');
my $baz_attr = Foo->meta->get_attribute('baz');
my $gorch_attr = Foo->meta->get_attribute('gorch');

is($bar_attr->reader, 'get_bar', '... the bar attribute has the reader get_bar');
is($bar_attr->writer, 'set_bar', '... the bar attribute has the writer set_bar');
is($bar_attr->associated_class, Foo->meta, '... and the bar attribute is associated with Foo->meta');

is($bar_attr->get_read_method,  'get_bar', '... $attr does have an read method');
is($bar_attr->get_write_method, 'set_bar', '... $attr does have an write method');

{
    my $reader = $bar_attr->get_read_method_ref;
    my $writer = $bar_attr->get_write_method_ref;

    isa_ok($reader, 'Class::MOP::Method');
    isa_ok($writer, 'Class::MOP::Method');

    is($reader->fully_qualified_name, 'Foo::get_bar', '... it is the sub we are looking for');
    is($writer->fully_qualified_name, 'Foo::set_bar', '... it is the sub we are looking for');

    is(reftype($reader->body), 'CODE', '... it is a plain old sub');
    is(reftype($writer->body), 'CODE', '... it is a plain old sub');
}

is($baz_attr->accessor, 'baz', '... the bar attribute has the accessor baz');
is($baz_attr->associated_class, Foo->meta, '... and the bar attribute is associated with Foo->meta');

is($baz_attr->get_read_method,  'baz', '... $attr does have an read method');
is($baz_attr->get_write_method, 'baz', '... $attr does have an write method');

{
    my $reader = $baz_attr->get_read_method_ref;
    my $writer = $baz_attr->get_write_method_ref;

    isa_ok($reader, 'Class::MOP::Method');
    isa_ok($writer, 'Class::MOP::Method');

    is($reader, $writer, '... they are the same method');

    is($reader->fully_qualified_name, 'Foo::baz', '... it is the sub we are looking for');
    is($writer->fully_qualified_name, 'Foo::baz', '... it is the sub we are looking for');
}

is(ref($gorch_attr->reader), 'HASH', '... the gorch attribute has the reader get_gorch (HASH ref)');
is($gorch_attr->associated_class, Foo->meta, '... and the gorch attribute is associated with Foo->meta');

is($gorch_attr->get_read_method,  'get_gorch', '... $attr does have an read method');
ok(!$gorch_attr->get_write_method, '... $attr does not have an write method');

{
    my $reader = $gorch_attr->get_read_method_ref;
    my $writer = $gorch_attr->get_write_method_ref;

    isa_ok($reader, 'Class::MOP::Method');
    ok(blessed($writer), '... it is not a plain old sub');
    isa_ok($writer, 'Class::MOP::Method');

    is($reader->fully_qualified_name, 'Foo::get_gorch', '... it is the sub we are looking for');
    is($writer->fully_qualified_name, 'Foo::__ANON__', '... it is the sub we are looking for');
}

done_testing;
