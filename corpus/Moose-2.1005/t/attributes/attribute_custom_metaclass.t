#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;


{
    package Foo::Meta::Attribute;
    use Moose;

    extends 'Moose::Meta::Attribute';

    around 'new' => sub {
        my $next = shift;
        my $self = shift;
        my $name = shift;
        $next->($self, $name, (is => 'rw', isa => 'Foo'), @_);
    };

    package Foo;
    use Moose;

    has 'foo' => (metaclass => 'Foo::Meta::Attribute');
}
{
    my $foo = Foo->new;
    isa_ok($foo, 'Foo');

    my $foo_attr = Foo->meta->get_attribute('foo');
    isa_ok($foo_attr, 'Foo::Meta::Attribute');
    isa_ok($foo_attr, 'Moose::Meta::Attribute');

    is($foo_attr->name, 'foo', '... got the right name for our meta-attribute');
    ok($foo_attr->has_accessor, '... our meta-attrubute created the accessor for us');

    ok($foo_attr->has_type_constraint, '... our meta-attrubute created the type_constraint for us');

    my $foo_attr_type_constraint = $foo_attr->type_constraint;
    isa_ok($foo_attr_type_constraint, 'Moose::Meta::TypeConstraint');

    is($foo_attr_type_constraint->name, 'Foo', '... got the right type constraint name');
    is($foo_attr_type_constraint->parent->name, 'Object', '... got the right type constraint parent name');
}
{
    package Bar::Meta::Attribute;
    use Moose;

    extends 'Class::MOP::Attribute';

    package Bar;
    use Moose;

    ::is( ::exception {
        has 'bar' => (metaclass => 'Bar::Meta::Attribute');
    }, undef, '... the attribute metaclass need not be a Moose::Meta::Attribute as long as it behaves' );
}

{
    package Moose::Meta::Attribute::Custom::Foo;
    sub register_implementation { 'Foo::Meta::Attribute' }

    package Moose::Meta::Attribute::Custom::Bar;
    use Moose;

    extends 'Moose::Meta::Attribute';

    package Another::Foo;
    use Moose;

    ::is( ::exception {
        has 'foo' => (metaclass => 'Foo');
    }, undef, '... the attribute metaclass alias worked correctly' );

    ::is( ::exception {
        has 'bar' => (metaclass => 'Bar', is => 'bare');
    }, undef, '... the attribute metaclass alias worked correctly' );
}

{
    my $foo_attr = Another::Foo->meta->get_attribute('foo');
    isa_ok($foo_attr, 'Foo::Meta::Attribute');
    isa_ok($foo_attr, 'Moose::Meta::Attribute');

    my $bar_attr = Another::Foo->meta->get_attribute('bar');
    isa_ok($bar_attr, 'Moose::Meta::Attribute::Custom::Bar');
    isa_ok($bar_attr, 'Moose::Meta::Attribute');
}

done_testing;
