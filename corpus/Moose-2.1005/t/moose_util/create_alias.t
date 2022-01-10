#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Moose qw(does_ok);

BEGIN {
    package Foo::Meta::Role;
    use Moose::Role;
    Moose::Util::meta_class_alias
        FooRole => 'Foo::Meta::Role';

    package Foo::Meta::Class;
    use Moose;
    extends 'Moose::Meta::Class';
    with 'Foo::Meta::Role';
    Moose::Util::meta_class_alias
        FooClass => 'Foo::Meta::Class';

    package Foo::Meta::Role::Attribute;
    use Moose::Role;
    Moose::Util::meta_attribute_alias
        FooAttrRole => 'Foo::Meta::Role::Attribute';

    package Foo::Meta::Attribute;
    use Moose;
    extends 'Moose::Meta::Attribute';
    with 'Foo::Meta::Role::Attribute';
    Moose::Util::meta_attribute_alias
        FooAttrClass => 'Foo::Meta::Attribute';

    package Bar::Meta::Role;
    use Moose::Role;
    Moose::Util::meta_class_alias 'BarRole';

    package Bar::Meta::Class;
    use Moose;
    extends 'Moose::Meta::Class';
    with 'Bar::Meta::Role';
    Moose::Util::meta_class_alias 'BarClass';

    package Bar::Meta::Role::Attribute;
    use Moose::Role;
    Moose::Util::meta_attribute_alias 'BarAttrRole';

    package Bar::Meta::Attribute;
    use Moose;
    extends 'Moose::Meta::Attribute';
    with 'Bar::Meta::Role::Attribute';
    Moose::Util::meta_attribute_alias 'BarAttrClass';
}

package FooWithMetaClass;
use Moose -metaclass => 'FooClass';

has bar => (
    metaclass => 'FooAttrClass',
    is        => 'ro',
);


package FooWithMetaTrait;
use Moose -traits => 'FooRole';

has bar => (
    traits => [qw(FooAttrRole)],
    is     => 'ro',
);

package BarWithMetaClass;
use Moose -metaclass => 'BarClass';

has bar => (
    metaclass => 'BarAttrClass',
    is        => 'ro',
);


package BarWithMetaTrait;
use Moose -traits => 'BarRole';

has bar => (
    traits => [qw(BarAttrRole)],
    is     => 'ro',
);

package main;
my $fwmc_meta = FooWithMetaClass->meta;
my $fwmt_meta = FooWithMetaTrait->meta;
isa_ok($fwmc_meta, 'Foo::Meta::Class');
isa_ok($fwmc_meta->get_attribute('bar'), 'Foo::Meta::Attribute');
does_ok($fwmt_meta, 'Foo::Meta::Role');
does_ok($fwmt_meta->get_attribute('bar'), 'Foo::Meta::Role::Attribute');

my $bwmc_meta = BarWithMetaClass->meta;
my $bwmt_meta = BarWithMetaTrait->meta;
isa_ok($bwmc_meta, 'Bar::Meta::Class');
isa_ok($bwmc_meta->get_attribute('bar'), 'Bar::Meta::Attribute');
does_ok($bwmt_meta, 'Bar::Meta::Role');
does_ok($bwmt_meta->get_attribute('bar'), 'Bar::Meta::Role::Attribute');

done_testing;
