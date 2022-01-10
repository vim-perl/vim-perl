#!/usr/bin/perl

use strict;
use warnings;

use lib 't/lib', 'lib';

use Test::More;
use Test::Fatal;

{
    package My::SimpleTrait;

    use Moose::Role;

    sub simple { return 5 }
}

{
    package Foo;

    use Moose -traits => [ 'My::SimpleTrait' ];
}

can_ok( Foo->meta(), 'simple' );
is( Foo->meta()->simple(), 5,
    'Foo->meta()->simple() returns expected value' );

{
    package Bar;

    use Moose -traits => 'My::SimpleTrait';
}

can_ok( Bar->meta(), 'simple' );
is( Bar->meta()->simple(), 5,
    'Foo->meta()->simple() returns expected value' );

{
    package My::SimpleTrait2;

    use Moose::Role;

    # This needs to happen at compile time so it happens before we
    # apply traits to Bar
    BEGIN {
        has 'attr' =>
            ( is      => 'ro',
              default => 'something',
            );
    }

    sub simple { return 5 }
}

{
    package Bar;

    use Moose -traits => [ 'My::SimpleTrait2' ];
}

can_ok( Bar->meta(), 'simple' );
is( Bar->meta()->simple(), 5,
    'Bar->meta()->simple() returns expected value' );
can_ok( Bar->meta(), 'attr' );
is( Bar->meta()->attr(), 'something',
    'Bar->meta()->attr() returns expected value' );

{
    package My::SimpleTrait3;

    use Moose::Role;

    BEGIN {
        has 'attr2' =>
            ( is      => 'ro',
              default => 'something',
            );
    }

    sub simple2 { return 55 }
}

{
    package Baz;

    use Moose -traits => [ 'My::SimpleTrait2', 'My::SimpleTrait3' ];
}

can_ok( Baz->meta(), 'simple' );
is( Baz->meta()->simple(), 5,
    'Baz->meta()->simple() returns expected value' );
can_ok( Baz->meta(), 'attr' );
is( Baz->meta()->attr(), 'something',
    'Baz->meta()->attr() returns expected value' );
can_ok( Baz->meta(), 'simple2' );
is( Baz->meta()->simple2(), 55,
    'Baz->meta()->simple2() returns expected value' );
can_ok( Baz->meta(), 'attr2' );
is( Baz->meta()->attr2(), 'something',
    'Baz->meta()->attr2() returns expected value' );

{
    package My::Trait::AlwaysRO;

    use Moose::Role;

    around '_process_new_attribute', '_process_inherited_attribute' =>
        sub {
            my $orig = shift;
            my ( $self, $name, %args ) = @_;

            $args{is} = 'ro';

            return $self->$orig( $name, %args );
        };
}

{
    package Quux;

    use Moose -traits => [ 'My::Trait::AlwaysRO' ];

    has 'size' =>
        ( is  => 'rw',
          isa => 'Int',
        );
}

ok( Quux->meta()->has_attribute('size'),
    'Quux has size attribute' );
ok( ! Quux->meta()->get_attribute('size')->writer(),
    'size attribute does not have a writer' );

{
    package My::Class::Whatever;

    use Moose::Role;

    sub whatever { 42 }

    package Moose::Meta::Class::Custom::Trait::Whatever;

    sub register_implementation {
        return 'My::Class::Whatever';
    }
}

{
    package RanOutOfNames;

    use Moose -traits => [ 'Whatever' ];
}

ok( RanOutOfNames->meta()->meta()->has_method('whatever'),
    'RanOutOfNames->meta() has whatever method' );

{
    package Role::Foo;

    use Moose::Role -traits => [ 'My::SimpleTrait' ];
}

can_ok( Role::Foo->meta(), 'simple' );
is( Role::Foo->meta()->simple(), 5,
    'Role::Foo->meta()->simple() returns expected value' );

{
    require Moose::Util::TypeConstraints;
    like(
        exception {
            Moose::Util::TypeConstraints->import(
                -traits => 'My::SimpleTrait' );
        },
        qr/does not have an init_meta/,
        'cannot provide -traits to an exporting module that does not init_meta'
    );
}

{
    package Foo::Subclass;

    use Moose -traits => [ 'My::SimpleTrait3' ];

    extends 'Foo';
}

can_ok( Foo::Subclass->meta(), 'simple' );
is( Foo::Subclass->meta()->simple(), 5,
    'Foo::Subclass->meta()->simple() returns expected value' );
is( Foo::Subclass->meta()->simple2(), 55,
    'Foo::Subclass->meta()->simple2() returns expected value' );
can_ok( Foo::Subclass->meta(), 'attr2' );
is( Foo::Subclass->meta()->attr2(), 'something',
    'Foo::Subclass->meta()->attr2() returns expected value' );

{

    package Class::WithAlreadyPresentTrait;
    use Moose -traits => 'My::SimpleTrait';

    has an_attr => ( is => 'ro' );
}

is( exception {
    my $instance = Class::WithAlreadyPresentTrait->new( an_attr => 'value' );
    is( $instance->an_attr, 'value', 'Can get value' );
}, undef, 'Can create instance and access attributes' );

{

    package Class::WhichLoadsATraitFromDisk;

    # Any role you like here, the only important bit is that it gets
    # loaded from disk and has not already been defined.
    use Moose -traits => 'Role::Parent';

    has an_attr => ( is => 'ro' );
}

is( exception {
    my $instance = Class::WhichLoadsATraitFromDisk->new( an_attr => 'value' );
    is( $instance->an_attr, 'value', 'Can get value' );
}, undef, 'Can create instance and access attributes' );

done_testing;
