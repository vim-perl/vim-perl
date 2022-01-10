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

    package Role::Bar;
    use Moose::Role;

    package Role::ExcludesFoo;
    use Moose::Role;
    excludes 'Role::Foo';

    package Role::DoesExcludesFoo;
    use Moose::Role;
    with 'Role::ExcludesFoo';

    package Role::DoesFoo;
    use Moose::Role;
    with 'Role::Foo';
}

ok(Role::ExcludesFoo->meta->excludes_role('Role::Foo'), '... got the right exclusions');
ok(Role::DoesExcludesFoo->meta->excludes_role('Role::Foo'), '... got the right exclusions');

# test simple exclusion
isnt( exception {
    Moose::Meta::Role::Application::RoleSummation->new->apply(
        Moose::Meta::Role::Composite->new(
            roles => [
                Role::Foo->meta,
                Role::ExcludesFoo->meta,
            ]
        )
    );
}, undef, '... this fails as expected' );

# test no conflicts
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
    }, undef, '... this lives as expected' );
}

# test no conflicts w/exclusion
{
    my $c = Moose::Meta::Role::Composite->new(
        roles => [
            Role::Bar->meta,
            Role::ExcludesFoo->meta,
        ]
    );
    isa_ok($c, 'Moose::Meta::Role::Composite');

    is($c->name, 'Role::Bar|Role::ExcludesFoo', '... got the composite role name');

    is( exception {
        Moose::Meta::Role::Application::RoleSummation->new->apply($c);
    }, undef, '... this lives as expected' );

    is_deeply([$c->get_excluded_roles_list], ['Role::Foo'], '... has excluded roles');
}


# test conflict with an "inherited" exclusion
isnt( exception {
    Moose::Meta::Role::Application::RoleSummation->new->apply(
        Moose::Meta::Role::Composite->new(
            roles => [
                Role::Foo->meta,
                Role::DoesExcludesFoo->meta,
            ]
        )
    );

}, undef, '... this fails as expected' );

# test conflict with an "inherited" exclusion of an "inherited" role
isnt( exception {
    Moose::Meta::Role::Application::RoleSummation->new->apply(
        Moose::Meta::Role::Composite->new(
            roles => [
                Role::DoesFoo->meta,
                Role::DoesExcludesFoo->meta,
            ]
        )
    );
}, undef, '... this fails as expected' );

done_testing;
