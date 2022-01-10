#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Test::Requires {
    'Test::Output' => '0.01', # skip all if not installed
};

{
    package NotMoose;

    sub new {
        my $class = shift;

        return bless { not_moose => 1 }, $class;
    }
}

{
    package Foo;
    use Moose;

    extends 'NotMoose';

    ::stderr_like(
        sub { Foo->meta->make_immutable },
        qr/\QNot inlining 'new' for Foo since it is not inheriting the default Moose::Object::new\E\s+\QIf you are certain you don't need to inline your constructor, specify inline_constructor => 0 in your call to Foo->meta->make_immutable/,
        'got a warning that Foo may not have an inlined constructor'
    );
}

is(
    Foo->meta->find_method_by_name('new')->body,
    NotMoose->can('new'),
    'Foo->new is inherited from NotMoose'
);

{
    package Bar;
    use Moose;

    extends 'NotMoose';

    ::stderr_is(
        sub { Bar->meta->make_immutable( replace_constructor => 1 ) },
        q{},
        'no warning when replace_constructor is true'
    );
}

is(
    Bar->meta->find_method_by_name('new')->package_name,
   'Bar',
    'Bar->new is inlined, and not inherited from NotMoose'
);

{
    package Baz;
    use Moose;

    Baz->meta->make_immutable;
}

{
    package Quux;
    use Moose;

    extends 'Baz';

    ::stderr_is(
        sub { Quux->meta->make_immutable },
        q{},
        'no warning when inheriting from a class that has already made itself immutable'
    );
}

{
    package My::Constructor;
    use base 'Moose::Meta::Method::Constructor';
}

{
    package CustomCons;
    use Moose;

    CustomCons->meta->make_immutable( constructor_class => 'My::Constructor' );
}

{
    package Subclass;
    use Moose;

    extends 'CustomCons';

    ::stderr_is(
        sub { Subclass->meta->make_immutable },
        q{},
        'no warning when inheriting from a class that has already made itself immutable'
    );
}

done_testing;
