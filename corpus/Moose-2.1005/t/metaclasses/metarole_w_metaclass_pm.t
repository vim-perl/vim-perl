#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Moose::Util::MetaRole;

BEGIN
{
    package My::Meta::Class;
    use Moose;
    extends 'Moose::Meta::Class';
}

BEGIN
{
    package My::Meta::Attribute;
    use Moose;
    extends 'Moose::Meta::Attribute';
}

BEGIN
{
    package My::Meta::Method;
    use Moose;
    extends 'Moose::Meta::Method';
}

BEGIN
{
    package My::Meta::Instance;
    use Moose;
    extends 'Moose::Meta::Instance';
}

BEGIN
{
    package Role::Foo;
    use Moose::Role;
    has 'foo' => ( is => 'ro', default => 10 );
}

{
    package My::Class;

    use metaclass 'My::Meta::Class';
    use Moose;
}

{
    package My::Class2;

    use metaclass 'My::Meta::Class' => (
        attribute_metaclass => 'My::Meta::Attribute',
        method_metaclass    => 'My::Meta::Method',
        instance_metaclass  => 'My::Meta::Instance',
    );

    use Moose;
}

{
    Moose::Util::MetaRole::apply_metaroles(
        for             => 'My::Class',
        class_metaroles => { class => ['Role::Foo'] },
    );

    ok( My::Class->meta()->meta()->does_role('Role::Foo'),
        'apply Role::Foo to My::Class->meta()' );
    has_superclass( My::Class->meta(), 'My::Meta::Class',
                    'apply_metaroles works with metaclass.pm' );
}

{
    Moose::Util::MetaRole::apply_metaroles(
        for             => 'My::Class2',
        class_metaroles => {
            attribute => ['Role::Foo'],
            method    => ['Role::Foo'],
            instance  => ['Role::Foo'],
        },
    );

    ok( My::Class2->meta()->attribute_metaclass()->meta()->does_role('Role::Foo'),
        q{apply Role::Foo to My::Class2->meta()'s attribute metaclass} );
    has_superclass( My::Class2->meta()->attribute_metaclass(), 'My::Meta::Attribute',
                    '... and this does not interfere with attribute metaclass set via metaclass.pm' );
    ok( My::Class2->meta()->method_metaclass()->meta()->does_role('Role::Foo'),
        q{apply Role::Foo to My::Class2->meta()'s method metaclass} );
    has_superclass( My::Class2->meta()->method_metaclass(), 'My::Meta::Method',
                    '... and this does not interfere with method metaclass set via metaclass.pm' );
    ok( My::Class2->meta()->instance_metaclass()->meta()->does_role('Role::Foo'),
        q{apply Role::Foo to My::Class2->meta()'s instance metaclass} );
    has_superclass( My::Class2->meta()->instance_metaclass(), 'My::Meta::Instance',
                    '... and this does not interfere with instance metaclass set via metaclass.pm' );
}

# like isa_ok but works with a class name, not just refs
sub has_superclass {
    my $thing  = shift;
    my $parent = shift;
    my $desc   = shift;

    my %supers = map { $_ => 1 } $thing->meta()->superclasses();

    local $Test::Builder::Level = $Test::Builder::Level + 1;

    ok( $supers{$parent}, $desc );
}

done_testing;
