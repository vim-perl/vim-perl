use strict;
use warnings;

use Test::More;
use Test::Fatal;

use Scalar::Util qw/isweak reftype/;

use Class::MOP::Instance;

can_ok( "Class::MOP::Instance", $_ ) for qw/
        new

        create_instance

        get_all_slots

        initialize_all_slots
        deinitialize_all_slots

        get_slot_value
        set_slot_value
        initialize_slot
        deinitialize_slot
        is_slot_initialized
        weaken_slot_value
        strengthen_slot_value

        inline_get_slot_value
        inline_set_slot_value
        inline_initialize_slot
        inline_deinitialize_slot
        inline_is_slot_initialized
        inline_weaken_slot_value
        inline_strengthen_slot_value
/;

{
        package Foo;
        use metaclass;

        Foo->meta->add_attribute('moosen');

        package Bar;
        use metaclass;
        use base qw/Foo/;

        Bar->meta->add_attribute('elken');
}

my $mi_foo = Foo->meta->get_meta_instance;
isa_ok($mi_foo, "Class::MOP::Instance");

is_deeply(
    [ $mi_foo->get_all_slots ],
    [ "moosen" ],
    '... get all slots for Foo');

my $mi_bar = Bar->meta->get_meta_instance;
isa_ok($mi_bar, "Class::MOP::Instance");

isnt($mi_foo, $mi_bar, '... they are not the same instance');

is_deeply(
    [ sort $mi_bar->get_all_slots ],
    [ "elken", "moosen" ],
    '... get all slots for Bar');

my $i_foo = $mi_foo->create_instance;
isa_ok($i_foo, "Foo");

{
    my $i_foo_2 = $mi_foo->create_instance;
    isa_ok($i_foo_2, "Foo");
    isnt($i_foo_2, $i_foo, '... not the same instance');
    is_deeply($i_foo, $i_foo_2, '... but the same structure');
}

ok(!$mi_foo->is_slot_initialized( $i_foo, "moosen" ), "slot not initialized");

ok(!defined($mi_foo->get_slot_value( $i_foo, "moosen" )), "... no value for slot");

$mi_foo->initialize_slot( $i_foo, "moosen" );

#Removed becayse slot initialization works differently now (groditi)
#ok($mi_foo->is_slot_initialized( $i_foo, "moosen" ), "slot initialized");

ok(!defined($mi_foo->get_slot_value( $i_foo, "moosen" )), "... but no value for slot");

$mi_foo->set_slot_value( $i_foo, "moosen", "the value" );

is($mi_foo->get_slot_value( $i_foo, "moosen" ), "the value", "... get slot value");
ok(!$i_foo->can('moosen'), '... Foo cant moosen');

my $ref = [];

$mi_foo->set_slot_value( $i_foo, "moosen", $ref );
$mi_foo->weaken_slot_value( $i_foo, "moosen" );

ok( isweak($i_foo->{moosen}), '... white box test of weaken' );
is( $mi_foo->get_slot_value( $i_foo, "moosen" ), $ref, "weak value is fetchable" );
ok( !isweak($mi_foo->get_slot_value( $i_foo, "moosen" )), "return value not weak" );

undef $ref;

is( $mi_foo->get_slot_value( $i_foo, "moosen" ), undef, "weak value destroyed" );

$ref = [];

$mi_foo->set_slot_value( $i_foo, "moosen", $ref );

undef $ref;

is( reftype( $mi_foo->get_slot_value( $i_foo, "moosen" ) ), "ARRAY", "value not weak yet" );

$mi_foo->weaken_slot_value( $i_foo, "moosen" );

is( $mi_foo->get_slot_value( $i_foo, "moosen" ), undef, "weak value destroyed" );

$ref = [];

$mi_foo->set_slot_value( $i_foo, "moosen", $ref );
$mi_foo->weaken_slot_value( $i_foo, "moosen" );
ok( isweak($i_foo->{moosen}), '... white box test of weaken' );
$mi_foo->strengthen_slot_value( $i_foo, "moosen" );
ok( !isweak($i_foo->{moosen}), '... white box test of weaken' );

undef $ref;

is( reftype( $mi_foo->get_slot_value( $i_foo, "moosen" ) ), "ARRAY", "weak value can be strengthened" );

$mi_foo->deinitialize_slot( $i_foo, "moosen" );

ok(!$mi_foo->is_slot_initialized( $i_foo, "moosen" ), "slot deinitialized");

ok(!defined($mi_foo->get_slot_value( $i_foo, "moosen" )), "... no value for slot");

done_testing;
