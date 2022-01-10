#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

do {
    package Role::Foo;
    use Moose::Role;

    sub foo { }


    package Consumer::Basic;
    use Moose;

    with 'Role::Foo';

    package Consumer::Excludes;
    use Moose;

    with 'Role::Foo' => { -excludes => 'foo' };

    package Consumer::Aliases;
    use Moose;

    with 'Role::Foo' => { -alias => { 'foo' => 'role_foo' } };

    package Consumer::Overrides;
    use Moose;

    with 'Role::Foo';

    sub foo { }
};

my @basic     = Consumer::Basic->meta->role_applications;
my @excludes  = Consumer::Excludes->meta->role_applications;
my @aliases   = Consumer::Aliases->meta->role_applications;
my @overrides = Consumer::Overrides->meta->role_applications;

is(@basic,     1);
is(@excludes,  1);
is(@aliases,   1);
is(@overrides, 1);

my $basic     = $basic[0];
my $excludes  = $excludes[0];
my $aliases   = $aliases[0];
my $overrides = $overrides[0];

isa_ok($basic,     'Moose::Meta::Role::Application::ToClass');
isa_ok($excludes,  'Moose::Meta::Role::Application::ToClass');
isa_ok($aliases,   'Moose::Meta::Role::Application::ToClass');
isa_ok($overrides, 'Moose::Meta::Role::Application::ToClass');

is($basic->role,     Role::Foo->meta);
is($excludes->role,  Role::Foo->meta);
is($aliases->role,   Role::Foo->meta);
is($overrides->role, Role::Foo->meta);

is($basic->class,     Consumer::Basic->meta);
is($excludes->class,  Consumer::Excludes->meta);
is($aliases->class,   Consumer::Aliases->meta);
is($overrides->class, Consumer::Overrides->meta);

is_deeply($basic->get_method_aliases,     {});
is_deeply($excludes->get_method_aliases,  {});
is_deeply($aliases->get_method_aliases,   { foo => 'role_foo' });
is_deeply($overrides->get_method_aliases, {});

is_deeply($basic->get_method_exclusions,     []);
is_deeply($excludes->get_method_exclusions,  ['foo']);
is_deeply($aliases->get_method_exclusions,   []);
is_deeply($overrides->get_method_exclusions, []);

done_testing;
