use strict;
use warnings;

use Test::More;
use Test::Fatal;

use Class::MOP;

{
    package Foo;
    use strict;
    use warnings;
    use metaclass;

    sub bar { 'Foo::bar' }
}

my $anon_class_id;
{
    my $instance;
    {
        my $anon_class = Class::MOP::Class->create_anon_class();
        isa_ok($anon_class, 'Class::MOP::Class');

        ($anon_class_id) = ($anon_class->name =~ /Class::MOP::Class::__ANON__::SERIAL::(\d+)/);

        ok(exists $main::Class::MOP::Class::__ANON__::SERIAL::{$anon_class_id . '::'}, '... the package exists');
        like($anon_class->name, qr/Class::MOP::Class::__ANON__::SERIAL::[0-9]+/, '... got an anon class package name');

        is_deeply(
            [$anon_class->superclasses],
            [],
            '... got an empty superclass list');
        is( exception {
            $anon_class->superclasses('Foo');
        }, undef, '... can add a superclass to anon class' );
        is_deeply(
            [$anon_class->superclasses],
            [ 'Foo' ],
            '... got the right superclass list');

        ok(!$anon_class->has_method('foo'), '... no foo method');
        is( exception {
            $anon_class->add_method('foo' => sub { "__ANON__::foo" });
        }, undef, '... added a method to my anon-class' );
        ok($anon_class->has_method('foo'), '... we have a foo method now');

        $instance = $anon_class->new_object();
        isa_ok($instance, $anon_class->name);
        isa_ok($instance, 'Foo');

        is($instance->foo, '__ANON__::foo', '... got the right return value of our foo method');
        is($instance->bar, 'Foo::bar', '... got the right return value of our bar method');
    }

    ok(exists $main::Class::MOP::Class::__ANON__::SERIAL::{$anon_class_id . '::'}, '... the package still exists');
}

ok(!exists $main::Class::MOP::Class::__ANON__::SERIAL::{$anon_class_id . '::'}, '... the package no longer exists');

# but it breaks down when we try to create another one ...

my $instance_2 = bless {} => ('Class::MOP::Class::__ANON__::SERIAL::' . $anon_class_id);
isa_ok($instance_2, ('Class::MOP::Class::__ANON__::SERIAL::' . $anon_class_id));
ok(!$instance_2->isa('Foo'), '... but the new instance is not a Foo');
ok(!$instance_2->can('foo'), '... and it can no longer call the foo method');

done_testing;
