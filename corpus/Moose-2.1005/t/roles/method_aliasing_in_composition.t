#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;


{
    package My::Role;
    use Moose::Role;

    sub foo { 'Foo::foo' }
    sub bar { 'Foo::bar' }
    sub baz { 'Foo::baz' }

    requires 'role_bar';

    package My::Class;
    use Moose;

    ::is( ::exception {
        with 'My::Role' => { -alias => { bar => 'role_bar' } };
    }, undef, '... this succeeds' );

    package My::Class::Failure;
    use Moose;

    ::like( ::exception {
        with 'My::Role' => { -alias => { bar => 'role_bar' } };
    }, qr/Cannot create a method alias if a local method of the same name exists/, '... this succeeds' );

    sub role_bar { 'FAIL' }
}

ok(My::Class->meta->has_method($_), "we have a $_ method") for qw(foo baz bar role_bar);

{
    package My::OtherRole;
    use Moose::Role;

    ::is( ::exception {
        with 'My::Role' => { -alias => { bar => 'role_bar' } };
    }, undef, '... this succeeds' );

    sub bar { 'My::OtherRole::bar' }

    package My::OtherRole::Failure;
    use Moose::Role;

    ::like( ::exception {
        with 'My::Role' => { -alias => { bar => 'role_bar' } };
    }, qr/Cannot create a method alias if a local method of the same name exists/, '... cannot alias to a name that exists' );

    sub role_bar { 'FAIL' }
}

ok(My::OtherRole->meta->has_method($_), "we have a $_ method") for qw(foo baz role_bar);
ok(!My::OtherRole->meta->requires_method('bar'), '... and the &bar method is not required');
ok(!My::OtherRole->meta->requires_method('role_bar'), '... and the &role_bar method is not required');

{
    package My::AliasingRole;
    use Moose::Role;

    ::is( ::exception {
        with 'My::Role' => { -alias => { bar => 'role_bar' } };
    }, undef, '... this succeeds' );
}

ok(My::AliasingRole->meta->has_method($_), "we have a $_ method") for qw(foo baz role_bar);
ok(!My::AliasingRole->meta->requires_method('bar'), '... and the &bar method is not required');

{
    package Foo::Role;
    use Moose::Role;

    sub foo { 'Foo::Role::foo' }

    package Bar::Role;
    use Moose::Role;

    sub foo { 'Bar::Role::foo' }

    package Baz::Role;
    use Moose::Role;

    sub foo { 'Baz::Role::foo' }

    package My::Foo::Class;
    use Moose;

    ::is( ::exception {
        with 'Foo::Role' => { -alias => { 'foo' => 'foo_foo' }, -excludes => 'foo' },
             'Bar::Role' => { -alias => { 'foo' => 'bar_foo' }, -excludes => 'foo' },
             'Baz::Role';
    }, undef, '... composed our roles correctly' );

    package My::Foo::Class::Broken;
    use Moose;

    ::like( ::exception {
        with 'Foo::Role' => { -alias => { 'foo' => 'foo_foo' }, -excludes => 'foo' },
             'Bar::Role' => { -alias => { 'foo' => 'foo_foo' }, -excludes => 'foo' },
             'Baz::Role';
    }, qr/Due to a method name conflict in roles 'Bar::Role' and 'Foo::Role', the method 'foo_foo' must be implemented or excluded by 'My::Foo::Class::Broken'/, '... composed our roles correctly' );
}

{
    my $foo = My::Foo::Class->new;
    isa_ok($foo, 'My::Foo::Class');
    can_ok($foo, $_) for qw/foo foo_foo bar_foo/;
    is($foo->foo, 'Baz::Role::foo', '... got the right method');
    is($foo->foo_foo, 'Foo::Role::foo', '... got the right method');
    is($foo->bar_foo, 'Bar::Role::foo', '... got the right method');
}

{
    package My::Foo::Role;
    use Moose::Role;

    ::is( ::exception {
        with 'Foo::Role' => { -alias => { 'foo' => 'foo_foo' }, -excludes => 'foo' },
             'Bar::Role' => { -alias => { 'foo' => 'bar_foo' }, -excludes => 'foo' },
             'Baz::Role';
    }, undef, '... composed our roles correctly' );
}

ok(My::Foo::Role->meta->has_method($_), "we have a $_ method") for qw/foo foo_foo bar_foo/;;
ok(!My::Foo::Role->meta->requires_method('foo'), '... and the &foo method is not required');


{
    package My::Foo::Role::Other;
    use Moose::Role;

    ::is( ::exception {
        with 'Foo::Role' => { -alias => { 'foo' => 'foo_foo' }, -excludes => 'foo' },
             'Bar::Role' => { -alias => { 'foo' => 'foo_foo' }, -excludes => 'foo' },
             'Baz::Role';
    }, undef, '... composed our roles correctly' );
}

ok(!My::Foo::Role::Other->meta->has_method('foo_foo'), "we dont have a foo_foo method");
ok(My::Foo::Role::Other->meta->requires_method('foo_foo'), '... and the &foo method is required');

{
    package My::Foo::AliasOnly;
    use Moose;

    ::is( ::exception {
        with 'Foo::Role' => { -alias => { 'foo' => 'foo_foo' } },
    }, undef, '... composed our roles correctly' );
}

ok(My::Foo::AliasOnly->meta->has_method('foo'), 'we have a foo method');
ok(My::Foo::AliasOnly->meta->has_method('foo_foo'), '.. and the aliased foo_foo method');

{
    package Role::Foo;
    use Moose::Role;

    sub x1 {}
    sub y1 {}
}

{
    package Role::Bar;
    use Moose::Role;

    ::is( ::exception {
        with 'Role::Foo' => {
            -alias    => { x1 => 'foo_x1' },
            -excludes => ['y1'],
        };
    }, undef, 'Compose Role::Foo into Role::Bar with alias and exclude' );

    sub x1 {}
    sub y1 {}
}

{
    my $bar = Role::Bar->meta;
    ok( $bar->has_method($_), "has $_ method" )
        for qw( x1 y1 foo_x1 );
}

{
    package Role::Baz;
    use Moose::Role;

    ::is( ::exception {
        with 'Role::Foo' => {
            -alias    => { x1 => 'foo_x1' },
            -excludes => ['y1'],
        };
    }, undef, 'Compose Role::Foo into Role::Baz with alias and exclude' );
}

{
    my $baz = Role::Baz->meta;
    ok( $baz->has_method($_), "has $_ method" )
        for qw( x1 foo_x1 );
    ok( ! $baz->has_method('y1'), 'Role::Baz has no y1 method' );
}

done_testing;
