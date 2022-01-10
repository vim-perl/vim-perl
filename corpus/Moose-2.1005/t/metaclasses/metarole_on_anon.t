use strict;
use warnings;

use Test::More;

use Moose ();
use Moose::Meta::Class;
use Moose::Util::MetaRole;

{
    package Foo;
    use Moose;
}

{
    package Role::Bar;
    use Moose::Role;
}

my $anon_name;

{
    my $anon_class = Moose::Meta::Class->create_anon_class(
        superclasses => ['Foo'],
        cache        => 1,
    );

    $anon_name = $anon_class->name;

    ok( $anon_name->meta, 'anon class has a metaclass' );
}

ok(
    $anon_name->meta,
    'cached anon class still has a metaclass after \$anon_class goes out of scope'
);

Moose::Util::MetaRole::apply_metaroles(
    for             => $anon_name,
    class_metaroles => {
        class => ['Role::Bar'],
    },
);

BAIL_OUT('Cannot continue if the anon class does not have a metaclass')
    unless $anon_name->can('meta');

my $meta = $anon_name->meta;
ok( $meta, 'cached anon class still has a metaclass applying a metarole' );

done_testing;
