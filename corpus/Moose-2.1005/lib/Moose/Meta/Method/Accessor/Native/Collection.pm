package Moose::Meta::Method::Accessor::Native::Collection;
BEGIN {
  $Moose::Meta::Method::Accessor::Native::Collection::AUTHORITY = 'cpan:STEVAN';
}
{
  $Moose::Meta::Method::Accessor::Native::Collection::VERSION = '2.1005';
}

use strict;
use warnings;

use Moose::Role;

requires qw( _adds_members );

sub _inline_coerce_new_values {
    my $self = shift;

    return unless $self->associated_attribute->should_coerce;

    return unless $self->_tc_member_type_can_coerce;

    return (
        '(' . $self->_new_members . ') = map { $member_coercion->($_) }',
                                             $self->_new_members . ';',
    );
}

sub _tc_member_type_can_coerce {
    my $self = shift;

    my $member_tc = $self->_tc_member_type;

    return $member_tc && $member_tc->has_coercion;
}

sub _tc_member_type {
    my $self = shift;

    my $tc = $self->associated_attribute->type_constraint;
    while ($tc) {
        return $tc->type_parameter
            if $tc->can('type_parameter');
        $tc = $tc->parent;
    }

    return;
}

sub _writer_value_needs_copy {
    my $self = shift;

    return $self->_constraint_must_be_checked
        && !$self->_check_new_members_only;
}

sub _inline_tc_code {
    my $self = shift;
    my ($value, $tc, $coercion, $message, $is_lazy) = @_;

    return unless $self->_constraint_must_be_checked;

    if ($self->_check_new_members_only) {
        return unless $self->_adds_members;

        return $self->_inline_check_member_constraint($self->_new_members);
    }
    else {
        return (
            $self->_inline_check_coercion($value, $tc, $coercion, $is_lazy),
            $self->_inline_check_constraint($value, $tc, $message, $is_lazy),
        );
    }
}

sub _check_new_members_only {
    my $self = shift;

    my $attr = $self->associated_attribute;

    my $tc = $attr->type_constraint;

    # If we have a coercion, we could come up with an entirely new value after
    # coercing, so we need to check everything,
    return 0 if $attr->should_coerce && $tc->has_coercion;

    # If the parent is our root type (ArrayRef, HashRef, etc), that means we
    # can just check the new members of the collection, because we know that
    # we will always be generating an appropriate collection type.
    #
    # However, if this type has its own constraint (it's Parameteriz_able_,
    # not Paramet_erized_), we don't know what is being checked by the
    # constraint, so we need to check the whole value, not just the members.
    return 1
        if $self->_is_root_type( $tc->parent )
            && ( $tc->isa('Moose::Meta::TypeConstraint::Parameterized')
                 || $tc->isa('Specio::Constraint::Parameterized') );

    return 0;
}

sub _inline_check_member_constraint {
    my $self = shift;
    my ($new_value) = @_;

    my $attr_name = $self->associated_attribute->name;

    my $check
        = $self->_tc_member_type->can_be_inlined
        ? '! (' . $self->_tc_member_type->_inline_check('$new_val') . ')'
        : ' !$member_tc->($new_val) ';

    return (
        'for my $new_val (' . $new_value . ') {',
            "if ($check) {",
                $self->_inline_throw_error(
                    '"A new member value for ' . $attr_name
                  . ' does not pass its type constraint because: "' . ' . '
                  . 'do { local $_ = $new_val; $member_message->($new_val) }',
                    'data => $new_val',
                ) . ';',
            '}',
        '}',
    );
}

sub _inline_get_old_value_for_trigger {
    my $self = shift;
    my ($instance, $old) = @_;

    my $attr = $self->associated_attribute;
    return unless $attr->has_trigger;

    return (
        'my ' . $old . ' = ' . $self->_has_value($instance),
            '? ' . $self->_copy_old_value($self->_get_value($instance)),
            ': ();',
    );
}

around _eval_environment => sub {
    my $orig = shift;
    my $self = shift;

    my $env = $self->$orig(@_);

    my $member_tc = $self->_tc_member_type;

    return $env unless $member_tc;

    $env->{'$member_tc'} = \( $member_tc->_compiled_type_constraint );
    $env->{'$member_coercion'} = \(
        $member_tc->coercion->_compiled_type_coercion
    ) if $member_tc->has_coercion;
    $env->{'$member_message'} = \(
        $member_tc->has_message
            ? $member_tc->message
            : $member_tc->_default_message
    );

    my $tc_env = $member_tc->inline_environment();

    $env = { %{$env}, %{$tc_env} };

    return $env;
};

no Moose::Role;

1;
