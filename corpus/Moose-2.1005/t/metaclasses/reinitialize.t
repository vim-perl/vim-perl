#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::Moose;
use Test::Fatal;

sub check_meta_sanity {
    my ($meta, $class) = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    isa_ok($meta, 'Moose::Meta::Class');
    is($meta->name, $class);
    ok($meta->has_method('foo'));
    isa_ok($meta->get_method('foo'), 'Moose::Meta::Method');
    ok($meta->has_attribute('bar'));
    isa_ok($meta->get_attribute('bar'), 'Moose::Meta::Attribute');

    if ( $meta->name eq 'Foo' ) {
        ok($meta->does_role('Role1'), 'does Role1');
        ok($meta->does_role('Role2'), 'does Role2');

        is_deeply(
            [
                map { [ $_->role->name, $_->class->name ] }
                    sort { $a->role->name cmp $b->role->name }
                    $meta->role_applications
            ],
            [
                [ 'Role1|Role2', 'Foo' ],
            ],
            'role applications for Role1 and Role2'
        );
    }
}

{
    package Role1;
    use Moose::Role;
}

{
    package Role2;
    use Moose::Role;
}

{
    package Foo;
    use Moose;
    sub foo {}
    with 'Role1', 'Role2';
    has bar => (is => 'ro');
}

check_meta_sanity(Foo->meta, 'Foo');

Moose::Meta::Class->reinitialize('Foo');
check_meta_sanity(Foo->meta, 'Foo');

{
    package Foo::Role::Method;
    use Moose::Role;

    has foo => (is => 'rw');
}

{
    package Foo::Role::Attribute;
    use Moose::Role;
    has oof => (is => 'rw');
}

Moose::Util::MetaRole::apply_metaroles(
    for => 'Foo',
    class_metaroles => {
        method    => ['Foo::Role::Method'],
        attribute => ['Foo::Role::Attribute'],
    },
);
check_meta_sanity(Foo->meta, 'Foo');
does_ok(Foo->meta->get_method('foo'), 'Foo::Role::Method');
does_ok(Foo->meta->get_attribute('bar'), 'Foo::Role::Attribute');

Moose::Meta::Class->reinitialize('Foo');
check_meta_sanity(Foo->meta, 'Foo');
does_ok(Foo->meta->get_method('foo'), 'Foo::Role::Method');
does_ok(Foo->meta->get_attribute('bar'), 'Foo::Role::Attribute');

Foo->meta->get_method('foo')->foo('TEST');
Foo->meta->get_attribute('bar')->oof('TSET');
is(Foo->meta->get_method('foo')->foo, 'TEST');
is(Foo->meta->get_attribute('bar')->oof, 'TSET');
Moose::Meta::Class->reinitialize('Foo');
check_meta_sanity(Foo->meta, 'Foo');
is(Foo->meta->get_method('foo')->foo, 'TEST');
is(Foo->meta->get_attribute('bar')->oof, 'TSET');

{
    package Bar::Role::Method;
    use Moose::Role;
}

{
    package Bar::Role::Attribute;
    use Moose::Role;
}

{
    package Bar;
    use Moose;
    Moose::Util::MetaRole::apply_metaroles(
        for => 'Bar',
        class_metaroles => {
            method    => ['Bar::Role::Method'],
            attribute => ['Bar::Role::Attribute'],
        },
    );
    sub foo {}
    has bar => (is => 'ro');
}

check_meta_sanity(Bar->meta, 'Bar');
does_ok(Bar->meta->get_method('foo'), 'Bar::Role::Method');
does_ok(Bar->meta->get_attribute('bar'), 'Bar::Role::Attribute');

Moose::Meta::Class->reinitialize('Bar');
check_meta_sanity(Bar->meta, 'Bar');
does_ok(Bar->meta->get_method('foo'), 'Bar::Role::Method');
does_ok(Bar->meta->get_attribute('bar'), 'Bar::Role::Attribute');
ok(!Moose::Util::does_role(Bar->meta->get_method('foo'), 'Foo::Role::Method'));
ok(!Moose::Util::does_role(Bar->meta->get_attribute('bar'), 'Foo::Role::Attribute'));

Moose::Util::MetaRole::apply_metaroles(
    for => 'Bar',
    class_metaroles => {
        method    => ['Foo::Role::Method'],
        attribute => ['Foo::Role::Attribute'],
    },
);
check_meta_sanity(Bar->meta, 'Bar');
does_ok(Bar->meta->get_method('foo'), 'Bar::Role::Method');
does_ok(Bar->meta->get_attribute('bar'), 'Bar::Role::Attribute');
does_ok(Bar->meta->get_method('foo'), 'Foo::Role::Method');
does_ok(Bar->meta->get_attribute('bar'), 'Foo::Role::Attribute');

{
    package Bar::Meta::Method;
    use Moose;
    BEGIN { extends 'Moose::Meta::Method' };
}

{
    package Bar::Meta::Attribute;
    use Moose;
    BEGIN { extends 'Moose::Meta::Attribute' };
}

like( exception {
    Moose::Meta::Class->reinitialize(
        'Bar',
        method_metaclass    => 'Bar::Meta::Method',
        attribute_metaclass => 'Bar::Meta::Attribute',
    );
}, qr/compatible/ );

{
    package Baz::Meta::Class;
    use Moose;
    BEGIN { extends 'Moose::Meta::Class' };

    sub initialize {
        my $self = shift;
        return $self->SUPER::initialize(
            @_,
            method_metaclass    => 'Bar::Meta::Method',
            attribute_metaclass => 'Bar::Meta::Attribute'
        );
    }
}

{
    package Baz;
    use Moose -metaclass => 'Baz::Meta::Class';
    sub foo {}
    has bar => (is => 'ro');
}

check_meta_sanity(Baz->meta, 'Baz');
isa_ok(Baz->meta->get_method('foo'), 'Bar::Meta::Method');
isa_ok(Baz->meta->get_attribute('bar'), 'Bar::Meta::Attribute');
Moose::Meta::Class->reinitialize('Baz');
check_meta_sanity(Baz->meta, 'Baz');
isa_ok(Baz->meta->get_method('foo'), 'Bar::Meta::Method');
isa_ok(Baz->meta->get_attribute('bar'), 'Bar::Meta::Attribute');

Moose::Util::MetaRole::apply_metaroles(
    for => 'Baz',
    class_metaroles => {
        method    => ['Foo::Role::Method'],
        attribute => ['Foo::Role::Attribute'],
    },
);
check_meta_sanity(Baz->meta, 'Baz');
isa_ok(Baz->meta->get_method('foo'), 'Bar::Meta::Method');
isa_ok(Baz->meta->get_attribute('bar'), 'Bar::Meta::Attribute');
does_ok(Baz->meta->get_method('foo'), 'Foo::Role::Method');
does_ok(Baz->meta->get_attribute('bar'), 'Foo::Role::Attribute');

{
    package Baz::Meta::Method;
    use Moose;
    extends 'Moose::Meta::Method';
}

{
    package Baz::Meta::Attribute;
    use Moose;
    extends 'Moose::Meta::Attribute';
}

like( exception {
    Moose::Meta::Class->reinitialize(
        'Baz',
        method_metaclass    => 'Baz::Meta::Method',
        attribute_metaclass => 'Baz::Meta::Attribute',
    );
}, qr/compatible/ );

{
    package Quux;
    use Moose;
    sub foo { }
    before foo => sub { };
    has bar => (is => 'ro');
    sub DEMOLISH { }
    __PACKAGE__->meta->make_immutable;
}

ok(Quux->meta->has_method('new'));
isa_ok(Quux->meta->get_method('new'), 'Moose::Meta::Method::Constructor');
ok(Quux->meta->has_method('meta'));
isa_ok(Quux->meta->get_method('meta'), 'Moose::Meta::Method::Meta');
ok(Quux->meta->has_method('foo'));
isa_ok(Quux->meta->get_method('foo'), 'Class::MOP::Method::Wrapped');
ok(Quux->meta->has_method('bar'));
isa_ok(Quux->meta->get_method('bar'), 'Moose::Meta::Method::Accessor');
ok(Quux->meta->has_method('DESTROY'));
isa_ok(Quux->meta->get_method('DESTROY'), 'Moose::Meta::Method::Destructor');
ok(Quux->meta->has_method('DEMOLISH'));
isa_ok(Quux->meta->get_method('DEMOLISH'), 'Moose::Meta::Method');

Quux->meta->make_mutable;
Moose::Meta::Class->reinitialize('Quux');
Quux->meta->make_immutable;

ok(Quux->meta->has_method('new'));
isa_ok(Quux->meta->get_method('new'), 'Moose::Meta::Method::Constructor');
ok(Quux->meta->has_method('meta'));
isa_ok(Quux->meta->get_method('meta'), 'Moose::Meta::Method::Meta');
ok(Quux->meta->has_method('foo'));
isa_ok(Quux->meta->get_method('foo'), 'Class::MOP::Method::Wrapped');
ok(Quux->meta->has_method('bar'));
isa_ok(Quux->meta->get_method('bar'), 'Moose::Meta::Method::Accessor');
ok(Quux->meta->has_method('DESTROY'));
isa_ok(Quux->meta->get_method('DESTROY'), 'Moose::Meta::Method::Destructor');
ok(Quux->meta->has_method('DEMOLISH'));
isa_ok(Quux->meta->get_method('DEMOLISH'), 'Moose::Meta::Method');

Quux->meta->make_mutable;
Moose::Util::MetaRole::apply_metaroles(
    for => 'Quux',
    class_metaroles => {
        method    => ['Foo::Role::Method'],
        attribute => ['Foo::Role::Attribute'],
    },
);
Quux->meta->make_immutable;

ok(Quux->meta->has_method('new'));
isa_ok(Quux->meta->get_method('new'), 'Moose::Meta::Method::Constructor');
{ local $TODO = "constructor methods don't get metaroles yet";
does_ok(Quux->meta->get_method('new'), 'Foo::Role::Method');
}
ok(Quux->meta->has_method('meta'));
isa_ok(Quux->meta->get_method('meta'), 'Moose::Meta::Method::Meta');
{ local $TODO = "meta methods don't get metaroles yet";
does_ok(Quux->meta->get_method('meta'), 'Foo::Role::Method');
}
ok(Quux->meta->has_method('foo'));
isa_ok(Quux->meta->get_method('foo'), 'Class::MOP::Method::Wrapped');
{ local $TODO = "modified methods don't get metaroles yet";
does_ok(Quux->meta->get_method('foo'), 'Foo::Role::Method');
}
ok(Quux->meta->has_method('bar'));
isa_ok(Quux->meta->get_method('bar'), 'Moose::Meta::Method::Accessor');
{ local $TODO = "accessor methods don't get metaroles yet";
does_ok(Quux->meta->get_method('bar'), 'Foo::Role::Method');
}
ok(Quux->meta->has_method('DESTROY'));
isa_ok(Quux->meta->get_method('DESTROY'), 'Moose::Meta::Method::Destructor');
{ local $TODO = "destructor methods don't get metaroles yet";
does_ok(Quux->meta->get_method('DESTROY'), 'Foo::Role::Method');
}
ok(Quux->meta->has_method('DEMOLISH'));
isa_ok(Quux->meta->get_method('DEMOLISH'), 'Moose::Meta::Method');
does_ok(Quux->meta->get_method('DEMOLISH'), 'Foo::Role::Method');

{
    package Role3;
    use Moose::Role;
    with 'Role1', 'Role2';
}

ok( Role3->meta->does_role('Role1'), 'Role3 does Role1' );
ok( Role3->meta->does_role('Role2'), 'Role3 does Role2' );

Moose::Meta::Role->reinitialize('Role3');

ok( Role3->meta->does_role('Role1'), 'Role3 does Role1 after reinitialize' );
ok( Role3->meta->does_role('Role2'), 'Role3 does Role2 after reinitialize' );

done_testing;
