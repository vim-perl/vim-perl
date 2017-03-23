use strict;
use warnings;

use Test::More;
use Test::Fatal;

use Class::MOP::Instance;

my $C = 'Class::MOP::Instance';

{
    my $instance  = '$self';
    my $slot_name = 'foo';
    my $value     = '$value';
    my $class     = '$class';

    is($C->inline_create_instance($class),
      'bless {} => $class',
      '... got the right code for create_instance');
    is($C->inline_get_slot_value($instance, $slot_name),
      q[$self->{"foo"}],
      '... got the right code for get_slot_value');

    is($C->inline_set_slot_value($instance, $slot_name, $value),
      q[$self->{"foo"} = $value],
      '... got the right code for set_slot_value');

    is($C->inline_initialize_slot($instance, $slot_name),
      '',
      '... got the right code for initialize_slot');

    is($C->inline_is_slot_initialized($instance, $slot_name),
      q[exists $self->{"foo"}],
      '... got the right code for get_slot_value');

    is($C->inline_weaken_slot_value($instance, $slot_name),
      q[Scalar::Util::weaken( $self->{"foo"} )],
      '... got the right code for weaken_slot_value');

    is($C->inline_strengthen_slot_value($instance, $slot_name),
      q[$self->{"foo"} = $self->{"foo"}],
      '... got the right code for strengthen_slot_value');
    is($C->inline_rebless_instance_structure($instance, $class),
      q[bless $self => $class],
      '... got the right code for rebless_instance_structure');
}

done_testing;
