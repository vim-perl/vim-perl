#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

{
    package Role::Metarole;
    use Moose::Role;
}

my ($role2);
{
    my $role1 = Moose::Meta::Role->create_anon_role(
        methods => {
            foo => sub { },
        },
    );
    ok($role1->has_method('foo'), "role has method foo");
    $role2 = Moose::Util::MetaRole::apply_metaroles(
        for => $role1->name,
        role_metaroles => { role => ['Role::Metarole'] },
    );
    isnt($role1, $role2, "anon role was reinitialized");
    is($role1->name, $role2->name, "but it's the same anon role");
    is_deeply([sort $role2->get_method_list], ['foo', 'meta'],
              "has the right methods");
}
is_deeply([sort $role2->get_method_list], ['foo', 'meta'],
          "still has the right methods");

done_testing;
