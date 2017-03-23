use strict;
use warnings;

use Scalar::Util 'reftype', 'blessed';

use Test::More;
use Test::Fatal;

use Class::MOP;
use Class::MOP::Attribute;
use Class::MOP::Method;


isnt( exception { Class::MOP::Attribute->name }, undef, q{... can't call name() as a class method} );


{
    my $attr = Class::MOP::Attribute->new('$foo');
    isa_ok($attr, 'Class::MOP::Attribute');

    is($attr->name, '$foo', '... $attr->name == $foo');
    ok($attr->has_init_arg, '... $attr does have an init_arg');
    is($attr->init_arg, '$foo', '... $attr init_arg is the name');

    ok(!$attr->has_accessor, '... $attr does not have an accessor');
    ok(!$attr->has_reader, '... $attr does not have an reader');
    ok(!$attr->has_writer, '... $attr does not have an writer');
    ok(!$attr->has_default, '... $attr does not have an default');
    ok(!$attr->has_builder, '... $attr does not have a builder');

    {
        my $reader = $attr->get_read_method_ref;
        my $writer = $attr->get_write_method_ref;

        ok(!blessed($reader), '... it is a plain old sub');
        ok(!blessed($writer), '... it is a plain old sub');

        is(reftype($reader), 'CODE', '... it is a plain old sub');
        is(reftype($writer), 'CODE', '... it is a plain old sub');
    }

    my $class = Class::MOP::Class->initialize('Foo');
    isa_ok($class, 'Class::MOP::Class');

    is( exception {
        $attr->attach_to_class($class);
    }, undef, '... attached a class successfully' );

    is($attr->associated_class, $class, '... the class was associated correctly');

    ok(!$attr->get_read_method, '... $attr does not have an read method');
    ok(!$attr->get_write_method, '... $attr does not have an write method');

    {
        my $reader = $attr->get_read_method_ref;
        my $writer = $attr->get_write_method_ref;

        ok(blessed($reader), '... it is a plain old sub');
        ok(blessed($writer), '... it is a plain old sub');

        isa_ok($reader, 'Class::MOP::Method');
        isa_ok($writer, 'Class::MOP::Method');
    }

    my $attr_clone = $attr->clone();
    isa_ok($attr_clone, 'Class::MOP::Attribute');
    isnt($attr, $attr_clone, '... but they are different instances');

    is($attr->associated_class, $attr_clone->associated_class, '... the associated classes are the same though');
    is($attr->associated_class, $class, '... the associated classes are the same though');
    is($attr_clone->associated_class, $class, '... the associated classes are the same though');

    is_deeply($attr, $attr_clone, '... but they are the same inside');
}

{
    my $attr = Class::MOP::Attribute->new('$foo', (
        init_arg => '-foo',
        default  => 'BAR'
    ));
    isa_ok($attr, 'Class::MOP::Attribute');

    is($attr->name, '$foo', '... $attr->name == $foo');

    ok($attr->has_init_arg, '... $attr does have an init_arg');
    is($attr->init_arg, '-foo', '... $attr->init_arg == -foo');
    ok($attr->has_default, '... $attr does have an default');
    is($attr->default, 'BAR', '... $attr->default == BAR');
    ok(!$attr->has_builder, '... $attr does not have a builder');

    ok(!$attr->has_accessor, '... $attr does not have an accessor');
    ok(!$attr->has_reader, '... $attr does not have an reader');
    ok(!$attr->has_writer, '... $attr does not have an writer');

    ok(!$attr->get_read_method, '... $attr does not have an read method');
    ok(!$attr->get_write_method, '... $attr does not have an write method');

    {
        my $reader = $attr->get_read_method_ref;
        my $writer = $attr->get_write_method_ref;

        ok(!blessed($reader), '... it is a plain old sub');
        ok(!blessed($writer), '... it is a plain old sub');

        is(reftype($reader), 'CODE', '... it is a plain old sub');
        is(reftype($writer), 'CODE', '... it is a plain old sub');
    }

    my $attr_clone = $attr->clone();
    isa_ok($attr_clone, 'Class::MOP::Attribute');
    isnt($attr, $attr_clone, '... but they are different instances');

    is($attr->associated_class, $attr_clone->associated_class, '... the associated classes are the same though');
    is($attr->associated_class, undef, '... the associated class is actually undef');
    is($attr_clone->associated_class, undef, '... the associated class is actually undef');

    is_deeply($attr, $attr_clone, '... but they are the same inside');
}

{
    my $attr = Class::MOP::Attribute->new('$foo', (
        accessor => 'foo',
        init_arg => '-foo',
        default  => 'BAR'
    ));
    isa_ok($attr, 'Class::MOP::Attribute');

    is($attr->name, '$foo', '... $attr->name == $foo');

    ok($attr->has_init_arg, '... $attr does have an init_arg');
    is($attr->init_arg, '-foo', '... $attr->init_arg == -foo');
    ok($attr->has_default, '... $attr does have an default');
    is($attr->default, 'BAR', '... $attr->default == BAR');

    ok($attr->has_accessor, '... $attr does have an accessor');
    is($attr->accessor, 'foo', '... $attr->accessor == foo');

    ok(!$attr->has_reader, '... $attr does not have an reader');
    ok(!$attr->has_writer, '... $attr does not have an writer');

    is($attr->get_read_method,  'foo', '... $attr does not have an read method');
    is($attr->get_write_method, 'foo', '... $attr does not have an write method');

    {
        my $reader = $attr->get_read_method_ref;
        my $writer = $attr->get_write_method_ref;

        ok(!blessed($reader), '... it is not a plain old sub');
        ok(!blessed($writer), '... it is not a plain old sub');

        is(reftype($reader), 'CODE', '... it is a plain old sub');
        is(reftype($writer), 'CODE', '... it is a plain old sub');
    }

    my $attr_clone = $attr->clone();
    isa_ok($attr_clone, 'Class::MOP::Attribute');
    isnt($attr, $attr_clone, '... but they are different instances');

    is_deeply($attr, $attr_clone, '... but they are the same inside');
}

{
    my $attr = Class::MOP::Attribute->new('$foo', (
        reader   => 'get_foo',
        writer   => 'set_foo',
        init_arg => '-foo',
        default  => 'BAR'
    ));
    isa_ok($attr, 'Class::MOP::Attribute');

    is($attr->name, '$foo', '... $attr->name == $foo');

    ok($attr->has_init_arg, '... $attr does have an init_arg');
    is($attr->init_arg, '-foo', '... $attr->init_arg == -foo');
    ok($attr->has_default, '... $attr does have an default');
    is($attr->default, 'BAR', '... $attr->default == BAR');

    ok($attr->has_reader, '... $attr does have an reader');
    is($attr->reader, 'get_foo', '... $attr->reader == get_foo');
    ok($attr->has_writer, '... $attr does have an writer');
    is($attr->writer, 'set_foo', '... $attr->writer == set_foo');

    ok(!$attr->has_accessor, '... $attr does not have an accessor');

    is($attr->get_read_method,  'get_foo', '... $attr does not have an read method');
    is($attr->get_write_method, 'set_foo', '... $attr does not have an write method');

    {
        my $reader = $attr->get_read_method_ref;
        my $writer = $attr->get_write_method_ref;

        ok(!blessed($reader), '... it is not a plain old sub');
        ok(!blessed($writer), '... it is not a plain old sub');

        is(reftype($reader), 'CODE', '... it is a plain old sub');
        is(reftype($writer), 'CODE', '... it is a plain old sub');
    }

    my $attr_clone = $attr->clone();
    isa_ok($attr_clone, 'Class::MOP::Attribute');
    isnt($attr, $attr_clone, '... but they are different instances');

    is_deeply($attr, $attr_clone, '... but they are the same inside');
}

{
    my $attr = Class::MOP::Attribute->new('$foo');
    isa_ok($attr, 'Class::MOP::Attribute');

    my $attr_clone = $attr->clone('name' => '$bar');
    isa_ok($attr_clone, 'Class::MOP::Attribute');
    isnt($attr, $attr_clone, '... but they are different instances');

    isnt($attr->name, $attr_clone->name, '... we changes the name parameter');

    is($attr->name, '$foo', '... $attr->name == $foo');
    is($attr_clone->name, '$bar', '... $attr_clone->name == $bar');
}

{
    my $attr = Class::MOP::Attribute->new('$foo', (builder => 'foo_builder'));
    isa_ok($attr, 'Class::MOP::Attribute');

    ok(!$attr->has_default, '... $attr does not have a default');
    ok($attr->has_builder, '... $attr does have a builder');
    is($attr->builder, 'foo_builder', '... $attr->builder == foo_builder');

}

{
    for my $value ({}, bless({}, 'Foo')) {
        like( exception {
            Class::MOP::Attribute->new('$foo', default => $value);
        }, qr/References are not allowed as default values/ );
    }
}

{
    my $attr;
    is( exception {
        my $meth = Class::MOP::Method->wrap(sub {shift}, name => 'foo', package_name => 'bar');
        $attr = Class::MOP::Attribute->new('$foo', default => $meth);
    }, undef, 'Class::MOP::Methods accepted as default' );

    is($attr->default(42), 42, 'passthrough for default on attribute');
}

done_testing;
