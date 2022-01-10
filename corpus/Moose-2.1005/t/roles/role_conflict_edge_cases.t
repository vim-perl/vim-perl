#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;

=pod

Check for repeated inheritance causing
a method conflict (which is not really
a conflict)

=cut

{
    package Role::Base;
    use Moose::Role;

    sub foo { 'Role::Base::foo' }

    package Role::Derived1;
    use Moose::Role;

    with 'Role::Base';

    package Role::Derived2;
    use Moose::Role;

    with 'Role::Base';

    package My::Test::Class1;
    use Moose;

    ::is( ::exception {
        with 'Role::Derived1', 'Role::Derived2';
    }, undef, '... roles composed okay (no conflicts)' );
}

ok(Role::Base->meta->has_method('foo'), '... have the method foo as expected');
ok(Role::Derived1->meta->has_method('foo'), '... have the method foo as expected');
ok(Role::Derived2->meta->has_method('foo'), '... have the method foo as expected');
ok(My::Test::Class1->meta->has_method('foo'), '... have the method foo as expected');

is(My::Test::Class1->foo, 'Role::Base::foo', '... got the right value from method');

=pod

Check for repeated inheritance causing
a method conflict with method modifiers
(which is not really a conflict)

=cut

{
    package Role::Base2;
    use Moose::Role;

    override 'foo' => sub { super() . ' -> Role::Base::foo' };

    package Role::Derived3;
    use Moose::Role;

    with 'Role::Base2';

    package Role::Derived4;
    use Moose::Role;

    with 'Role::Base2';

    package My::Test::Class2::Base;
    use Moose;

    sub foo { 'My::Test::Class2::Base' }

    package My::Test::Class2;
    use Moose;

    extends 'My::Test::Class2::Base';

    ::is( ::exception {
        with 'Role::Derived3', 'Role::Derived4';
    }, undef, '... roles composed okay (no conflicts)' );
}

ok(Role::Base2->meta->has_override_method_modifier('foo'), '... have the method foo as expected');
ok(Role::Derived3->meta->has_override_method_modifier('foo'), '... have the method foo as expected');
ok(Role::Derived4->meta->has_override_method_modifier('foo'), '... have the method foo as expected');
ok(My::Test::Class2->meta->has_method('foo'), '... have the method foo as expected');
isa_ok(My::Test::Class2->meta->get_method('foo'), 'Moose::Meta::Method::Overridden');
ok(My::Test::Class2::Base->meta->has_method('foo'), '... have the method foo as expected');
isa_ok(My::Test::Class2::Base->meta->get_method('foo'), 'Class::MOP::Method');

is(My::Test::Class2::Base->foo, 'My::Test::Class2::Base', '... got the right value from method');
is(My::Test::Class2->foo, 'My::Test::Class2::Base -> Role::Base::foo', '... got the right value from method');

=pod

Check for repeated inheritance of the
same code. There are no conflicts with
before/around/after method modifiers.

This tests around, but should work the
same for before/afters as well

=cut

{
    package Role::Base3;
    use Moose::Role;

    around 'foo' => sub { 'Role::Base::foo(' . (shift)->() . ')' };

    package Role::Derived5;
    use Moose::Role;

    with 'Role::Base3';

    package Role::Derived6;
    use Moose::Role;

    with 'Role::Base3';

    package My::Test::Class3::Base;
    use Moose;

    sub foo { 'My::Test::Class3::Base' }

    package My::Test::Class3;
    use Moose;

    extends 'My::Test::Class3::Base';

    ::is( ::exception {
        with 'Role::Derived5', 'Role::Derived6';
    }, undef, '... roles composed okay (no conflicts)' );
}

ok(Role::Base3->meta->has_around_method_modifiers('foo'), '... have the method foo as expected');
ok(Role::Derived5->meta->has_around_method_modifiers('foo'), '... have the method foo as expected');
ok(Role::Derived6->meta->has_around_method_modifiers('foo'), '... have the method foo as expected');
ok(My::Test::Class3->meta->has_method('foo'), '... have the method foo as expected');
isa_ok(My::Test::Class3->meta->get_method('foo'), 'Class::MOP::Method::Wrapped');
ok(My::Test::Class3::Base->meta->has_method('foo'), '... have the method foo as expected');
isa_ok(My::Test::Class3::Base->meta->get_method('foo'), 'Class::MOP::Method');

is(My::Test::Class3::Base->foo, 'My::Test::Class3::Base', '... got the right value from method');
is(My::Test::Class3->foo, 'Role::Base::foo(My::Test::Class3::Base)', '... got the right value from method');

=pod

Check for repeated inheritance causing
a attr conflict (which is not really
a conflict)

=cut

{
    package Role::Base4;
    use Moose::Role;

    has 'foo' => (is => 'ro', default => 'Role::Base::foo');

    package Role::Derived7;
    use Moose::Role;

    with 'Role::Base4';

    package Role::Derived8;
    use Moose::Role;

    with 'Role::Base4';

    package My::Test::Class4;
    use Moose;

    ::is( ::exception {
        with 'Role::Derived7', 'Role::Derived8';
    }, undef, '... roles composed okay (no conflicts)' );
}

ok(Role::Base4->meta->has_attribute('foo'), '... have the attribute foo as expected');
ok(Role::Derived7->meta->has_attribute('foo'), '... have the attribute foo as expected');
ok(Role::Derived8->meta->has_attribute('foo'), '... have the attribute foo as expected');
ok(My::Test::Class4->meta->has_attribute('foo'), '... have the attribute foo as expected');

is(My::Test::Class4->new->foo, 'Role::Base::foo', '... got the right value from method');

done_testing;
