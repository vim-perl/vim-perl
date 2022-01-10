#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Moose::Meta::Class;

{
    package Class;
    use Moose;

    package Foo;
    use Moose::Role;
    sub foo_role_applied { 1 }

    package Bar;
    use Moose::Role;
    sub bar_role_applied { 1 }
}

# try without caching first

{
    my $class_and_foo_1 = Moose::Meta::Class->create_anon_class(
        superclasses => ['Class'],
        roles        => ['Foo'],
    );

    my $class_and_foo_2 = Moose::Meta::Class->create_anon_class(
        superclasses => ['Class'],
        roles        => ['Foo'],
    );

    isnt $class_and_foo_1->name, $class_and_foo_2->name,
      'creating the same class twice without caching results in 2 classes';

    map { ok $_->name->foo_role_applied } ($class_and_foo_1, $class_and_foo_2);
}

# now try with caching

{
    my $class_and_foo_1 = Moose::Meta::Class->create_anon_class(
        superclasses => ['Class'],
        roles        => ['Foo'],
        cache        => 1,
    );

    my $class_and_foo_2 = Moose::Meta::Class->create_anon_class(
        superclasses => ['Class'],
        roles        => ['Foo'],
        cache        => 1,
    );

    is $class_and_foo_1->name, $class_and_foo_2->name,
      'with cache, the same class is the same class';

    map { ok $_->name->foo_role_applied } ($class_and_foo_1, $class_and_foo_2);

    my $class_and_bar = Moose::Meta::Class->create_anon_class(
        superclasses => ['Class'],
        roles        => ['Bar'],
        cache        => 1,
    );

    isnt $class_and_foo_1->name, $class_and_bar,
      'class_and_foo and class_and_bar are different';

    ok $class_and_bar->name->bar_role_applied;
}

# This tests that a cached metaclass can be reinitialized and still retain its
# metaclass object.
{
    my $name = Moose::Meta::Class->create_anon_class(
        superclasses => ['Class'],
        cache        => 1,
    )->name;

    $name->meta->reinitialize( $name );

    can_ok( $name, 'meta' );
}

{
    my $name;
    {
        my $meta = Moose::Meta::Class->create_anon_class(
            superclasses => ['Class'],
            cache        => 1,
        );
        $name = $meta->name;
        ok(!Class::MOP::metaclass_is_weak($name), "cache implies weaken => 0");
    }
    ok(Class::MOP::class_of($name), "cache implies weaken => 0");
    Class::MOP::remove_metaclass_by_name($name);
}

{
    my $name;
    {
        my $meta = Moose::Meta::Class->create_anon_class(
            superclasses => ['Class'],
            cache        => 1,
            weaken       => 1,
        );
        my $name = $meta->name;
        ok(Class::MOP::metaclass_is_weak($name), "but we can override this");
    }
    ok(!Class::MOP::class_of($name), "but we can override this");
}

{
    my $meta = Moose::Meta::Class->create_anon_class(
        superclasses => ['Class'],
        cache        => 1,
    );
    ok(!Class::MOP::metaclass_is_weak($meta->name),
       "creates a nonweak metaclass");
    Scalar::Util::weaken($meta);
    Class::MOP::remove_metaclass_by_name($meta->name);
    ok(!$meta, "removing a cached anon class means it's actually gone");
}

done_testing;
