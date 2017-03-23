#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::Moose;
use Moose::Util qw( does_role );

{
    package Foo::Meta::Attribute;
    use Moose::Role;
}

{
    package Foo::Meta::Attribute2;
    use Moose::Role;
}

{
    package Foo::Role;
    use Moose::Role;

    has foo => (is => 'ro');
}

{
    package Foo;
    use Moose;
    Moose::Util::MetaRole::apply_metaroles(
        for => __PACKAGE__,
        class_metaroles => { attribute => ['Foo::Meta::Attribute'] },
        role_metaroles  => { applied_attribute => ['Foo::Meta::Attribute2'] },
    );
    with 'Foo::Role';

    has bar => (is => 'ro');
}

ok(Moose::Util::does_role(Foo->meta->get_attribute('bar'), 'Foo::Meta::Attribute'), "attrs defined in the class get the class metarole applied");
ok(!Moose::Util::does_role(Foo->meta->get_attribute('bar'), 'Foo::Meta::Attribute2'), "attrs defined in the class don't get the role metarole applied");
ok(!Moose::Util::does_role(Foo->meta->get_attribute('foo'), 'Foo::Meta::Attribute'), "attrs defined in the role don't get the metarole applied");
ok(!Moose::Util::does_role(Foo->meta->get_attribute('foo'), 'Foo::Meta::Attribute'), "attrs defined in the role don't get the role metarole defined in the class applied");

{
    package Bar::Meta::Attribute;
    use Moose::Role;
}

{
    package Bar::Meta::Attribute2;
    use Moose::Role;
}

{
    package Bar::Role;
    use Moose::Role;
    Moose::Util::MetaRole::apply_metaroles(
        for => __PACKAGE__,
        class_metaroles => { attribute => ['Bar::Meta::Attribute'] },
        role_metaroles  => { applied_attribute => ['Bar::Meta::Attribute2'] },
    );

    has foo => (is => 'ro');
}

{
    package Bar;
    use Moose;
    with 'Bar::Role';

    has bar => (is => 'ro');
}

ok(!Moose::Util::does_role(Bar->meta->get_attribute('bar'), 'Bar::Meta::Attribute'), "attrs defined in the class don't get the class metarole from the role applied");
ok(!Moose::Util::does_role(Bar->meta->get_attribute('bar'), 'Bar::Meta::Attribute2'), "attrs defined in the class don't get the role metarole applied");
ok(Moose::Util::does_role(Bar->meta->get_attribute('foo'), 'Bar::Meta::Attribute2'), "attrs defined in the role get the role metarole applied");
ok(!Moose::Util::does_role(Bar->meta->get_attribute('foo'), 'Bar::Meta::Attribute'), "attrs defined in the role don't get the class metarole applied");

{
    package Baz::Meta::Attribute;
    use Moose::Role;
}

{
    package Baz::Meta::Attribute2;
    use Moose::Role;
}

{
    package Baz::Role;
    use Moose::Role;
    Moose::Util::MetaRole::apply_metaroles(
        for => __PACKAGE__,
        class_metaroles => { attribute => ['Baz::Meta::Attribute'] },
        role_metaroles  => { applied_attribute => ['Baz::Meta::Attribute2'] },
    );

    has foo => (is => 'ro');
}

{
    package Baz;
    use Moose;
    Moose::Util::MetaRole::apply_metaroles(
        for => __PACKAGE__,
        class_metaroles => { attribute => ['Baz::Meta::Attribute'] },
        role_metaroles  => { applied_attribute => ['Baz::Meta::Attribute2'] },
    );
    with 'Baz::Role';

    has bar => (is => 'ro');
}

ok(Moose::Util::does_role(Baz->meta->get_attribute('bar'), 'Baz::Meta::Attribute'), "attrs defined in the class get the class metarole applied");
ok(!Moose::Util::does_role(Baz->meta->get_attribute('bar'), 'Baz::Meta::Attribute2'), "attrs defined in the class don't get the role metarole applied");
ok(Moose::Util::does_role(Baz->meta->get_attribute('foo'), 'Baz::Meta::Attribute2'), "attrs defined in the role get the role metarole applied");
ok(!Moose::Util::does_role(Baz->meta->get_attribute('foo'), 'Baz::Meta::Attribute'), "attrs defined in the role don't get the class metarole applied");

{
    package Accessor::Modifying::Role;
    use Moose::Role;

    around _process_options => sub {
        my $orig = shift;
        my $self = shift;
        my ($name, $params) = @_;
        $self->$orig(@_);
        $params->{reader} .= '_foo';
    };
}

{
    package Plain::Role;
    use Moose::Role;

    has foo => (
        is  => 'ro',
        isa => 'Str',
    );
}

{
    package Class::With::Trait;
    use Moose;
    Moose::Util::MetaRole::apply_metaroles(
        for => __PACKAGE__,
        class_metaroles => {
            attribute => ['Accessor::Modifying::Role'],
        },
    );
    with 'Plain::Role';

    has bar => (
        is  => 'ro',
        isa => 'Str',
    );
}

{
    can_ok('Class::With::Trait', 'foo');
    can_ok('Class::With::Trait', 'bar_foo');
}

{
    package Role::With::Trait;
    use Moose::Role;
    Moose::Util::MetaRole::apply_metaroles(
        for => __PACKAGE__,
        role_metaroles => {
            applied_attribute => ['Accessor::Modifying::Role'],
        },
    );
    with 'Plain::Role';

    has foo => (
        is  => 'ro',
        isa => 'Str',
    );

    sub foo_test {
        my $self = shift;
        return $self->can('foo_foo');
    }
}

{
    package Class::With::Role::With::Trait;
    use Moose;
    with 'Role::With::Trait';

    has bar => (
        is  => 'ro',
        isa => 'Str',
    );

    sub bar_test {
        my $self = shift;
        return $self->can('bar');
    }
}

{
    can_ok('Class::With::Role::With::Trait', 'foo_foo');
    can_ok('Class::With::Role::With::Trait', 'bar');
}

{
    package Quux::Meta::Role::Attribute;
    use Moose::Role;
}

{
    package Quux::Role1;
    use Moose::Role;

    has foo => (traits => ['Quux::Meta::Role::Attribute'], is => 'ro');
    has baz => (is => 'ro');
}

{
    package Quux::Role2;
    use Moose::Role;
    Moose::Util::MetaRole::apply_metaroles(
        for            => __PACKAGE__,
        role_metaroles => {
            applied_attribute => ['Quux::Meta::Role::Attribute']
        },
    );

    has bar => (is => 'ro');
}

{
    package Quux;
    use Moose;
    with 'Quux::Role1', 'Quux::Role2';
}

{
    my $foo = Quux->meta->get_attribute('foo');
    does_ok($foo, 'Quux::Meta::Role::Attribute',
            "individual attribute trait applied correctly");

    my $baz = Quux->meta->get_attribute('baz');
    ok(! does_role($baz, 'Quux::Meta::Role::Attribute'),
       "applied_attribute traits do not end up applying to attributes from other roles during composition");

    my $bar = Quux->meta->get_attribute('bar');
    does_ok($bar, 'Quux::Meta::Role::Attribute',
            "attribute metarole applied correctly");
}

{
    package HasMeta;
    use Moose::Role;
    Moose::Util::MetaRole::apply_metaroles(
        for            => __PACKAGE__,
        role_metaroles => {
            applied_attribute => ['Quux::Meta::Role::Attribute']
        },
    );

    has foo => (is => 'ro');
}

{
    package NoMeta;
    use Moose::Role;

    with 'HasMeta';

    has bar => (is => 'ro');
}

{
    package ConsumesBoth;
    use Moose;
    with 'HasMeta', 'NoMeta';
}

{
    my $foo = ConsumesBoth->meta->get_attribute('foo');
    does_ok($foo, 'Quux::Meta::Role::Attribute',
            'applied_attribute traits are preserved when one role consumes another');

    my $bar = ConsumesBoth->meta->get_attribute('bar');
    ok(! does_role($bar, 'Quux::Meta::Role::Attribute'),
       "applied_attribute traits do not spill over from consumed role");
}



done_testing;
