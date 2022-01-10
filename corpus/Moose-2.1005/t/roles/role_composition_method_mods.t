#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;

use Moose::Meta::Role::Application::RoleSummation;
use Moose::Meta::Role::Composite;

{
    package Role::Foo;
    use Moose::Role;

    before foo => sub { 'Role::Foo::foo' };
    around foo => sub { 'Role::Foo::foo' };
    after  foo => sub { 'Role::Foo::foo' };
    around baz => sub { [ 'Role::Foo', @{shift->(@_)} ] };

    package Role::Bar;
    use Moose::Role;

    before bar => sub { 'Role::Bar::bar' };
    around bar => sub { 'Role::Bar::bar' };
    after  bar => sub { 'Role::Bar::bar' };

    package Role::Baz;
    use Moose::Role;

    with 'Role::Foo';
    around baz => sub { [ 'Role::Baz', @{shift->(@_)} ] };

}

{
  package Class::FooBar;
  use Moose;

  with 'Role::Baz';
  sub foo { 'placeholder' }
  sub baz { ['Class::FooBar'] }
}

#test modifier call order
{
    is_deeply(
        Class::FooBar->baz,
        ['Role::Baz','Role::Foo','Class::FooBar']
    );
}

# test simple overrides
{
    my $c = Moose::Meta::Role::Composite->new(
        roles => [
            Role::Foo->meta,
            Role::Bar->meta,
        ]
    );
    isa_ok($c, 'Moose::Meta::Role::Composite');

    is($c->name, 'Role::Foo|Role::Bar', '... got the composite role name');

    is( exception {
        Moose::Meta::Role::Application::RoleSummation->new->apply($c);
    }, undef, '... this succeeds as expected' );

    is_deeply(
        [ sort $c->get_method_modifier_list('before') ],
        [ 'bar', 'foo' ],
        '... got the right list of methods'
    );

    is_deeply(
        [ sort $c->get_method_modifier_list('after') ],
        [ 'bar', 'foo' ],
        '... got the right list of methods'
    );

    is_deeply(
        [ sort $c->get_method_modifier_list('around') ],
        [ 'bar', 'baz', 'foo' ],
        '... got the right list of methods'
    );
}

done_testing;
