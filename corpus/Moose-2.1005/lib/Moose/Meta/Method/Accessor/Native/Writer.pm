package Moose::Meta::Method::Accessor::Native::Writer;
BEGIN {
  $Moose::Meta::Method::Accessor::Native::Writer::AUTHORITY = 'cpan:STEVAN';
}
{
  $Moose::Meta::Method::Accessor::Native::Writer::VERSION = '2.1005';
}

use strict;
use warnings;

use List::MoreUtils qw( any );
use Moose::Util;

use Moose::Role;

with 'Moose::Meta::Method::Accessor::Native';

requires '_potential_value';

sub _generate_method {
    my $self = shift;

    my $inv         = '$self';
    my $slot_access = $self->_get_value($inv);

    return (
        'sub {',
            'my ' . $inv . ' = shift;',
            $self->_inline_curried_arguments,
            $self->_inline_writer_core($inv, $slot_access),
        '}',
    );
}

sub _inline_writer_core {
    my $self = shift;
    my ($inv, $slot_access) = @_;

    my $potential = $self->_potential_value($slot_access);
    my $old       = '@old';

    my @code;
    push @code, (
        $self->_inline_check_argument_count,
        $self->_inline_process_arguments($inv, $slot_access),
        $self->_inline_check_arguments('for writer'),
        $self->_inline_check_lazy($inv, '$type_constraint', '$type_coercion', '$type_message'),
    );

    if ($self->_return_value($slot_access)) {
        # some writers will save the return value in this variable when they
        # generate the potential value.
        push @code, 'my @return;'
    }

    push @code, (
        $self->_inline_coerce_new_values,
        $self->_inline_copy_native_value(\$potential),
        $self->_inline_tc_code($potential, '$type_constraint', '$type_coercion', '$type_message'),
        $self->_inline_get_old_value_for_trigger($inv, $old),
        $self->_inline_capture_return_value($slot_access),
        $self->_inline_set_new_value($inv, $potential, $slot_access),
        $self->_inline_trigger($inv, $slot_access, $old),
        $self->_inline_return_value($slot_access, 'for writer'),
    );

    return @code;
}

sub _inline_process_arguments { return }

sub _inline_check_arguments { return }

sub _inline_coerce_new_values { return }

sub _writer_value_needs_copy {
    my $self = shift;

    return $self->_constraint_must_be_checked;
}

sub _constraint_must_be_checked {
    my $self = shift;

    my $attr = $self->associated_attribute;

    return $attr->has_type_constraint
        && ( !$self->_is_root_type( $attr->type_constraint )
        || ( $attr->should_coerce && $attr->type_constraint->has_coercion ) );
}

sub _is_root_type {
    my $self = shift;
    my $type = shift;

    if (
        Moose::Util::does_role( $type, 'Specio::Constraint::Role::Interface' ) )
    {
        require Specio::Library::Builtins;
        return
            any { $type->is_same_type_as( Specio::Library::Builtins::t($_) ) }
        @{ $self->root_types };
    }
    else {
        my $name = $type->name;
        return any { $name eq $_ } @{ $self->root_types };
    }
}

sub _inline_copy_native_value {
    my $self = shift;
    my ($potential_ref) = @_;

    return unless $self->_writer_value_needs_copy;

    my $code = 'my $potential = ' . ${$potential_ref} . ';';

    ${$potential_ref} = '$potential';

    return $code;
}

around _inline_tc_code => sub {
    my $orig = shift;
    my $self = shift;
    my ($value, $tc, $coercion, $message, $for_lazy) = @_;

    return unless $for_lazy || $self->_constraint_must_be_checked;

    return $self->$orig(@_);
};

around _inline_check_constraint => sub {
    my $orig = shift;
    my $self = shift;
    my ($value, $tc, $message, $for_lazy) = @_;

    return unless $for_lazy || $self->_constraint_must_be_checked;

    return $self->$orig(@_);
};

sub _inline_capture_return_value { return }

sub _inline_set_new_value {
    my $self = shift;

    return $self->_inline_store_value(@_)
        if $self->_writer_value_needs_copy
        || !$self->_slot_access_can_be_inlined
        || !$self->_get_is_lvalue;

    return $self->_inline_optimized_set_new_value(@_);
}

sub _get_is_lvalue {
    my $self = shift;

    return $self->associated_attribute->associated_class->instance_metaclass->inline_get_is_lvalue;
}

sub _inline_optimized_set_new_value {
    my $self = shift;

    return $self->_inline_store_value(@_);
}

sub _return_value {
    my $self = shift;
    my ($slot_access) = @_;

    return $slot_access;
}

no Moose::Role;

1;
