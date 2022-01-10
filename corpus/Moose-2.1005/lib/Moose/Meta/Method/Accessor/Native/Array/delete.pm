package Moose::Meta::Method::Accessor::Native::Array::delete;
BEGIN {
  $Moose::Meta::Method::Accessor::Native::Array::delete::AUTHORITY = 'cpan:STEVAN';
}
{
  $Moose::Meta::Method::Accessor::Native::Array::delete::VERSION = '2.1005';
}

use strict;
use warnings;

use Moose::Role;

with 'Moose::Meta::Method::Accessor::Native::Array::Writer';

sub _minimum_arguments { 1 }

sub _maximum_arguments { 1 }

sub _inline_check_arguments {
    my $self = shift;

    return $self->_inline_check_var_is_valid_index('$_[0]');
}

sub _adds_members { 0 }

sub _potential_value {
    my $self = shift;
    my ($slot_access) = @_;

    return '(do { '
             . 'my @potential = @{ (' . $slot_access . ') }; '
             . '@return = splice @potential, $_[0], 1; '
             . '\@potential; '
         . '})';
}

sub _inline_optimized_set_new_value {
    my $self = shift;
    my ($inv, $new, $slot_access) = @_;

    return '@return = splice @{ (' . $slot_access . ') }, $_[0], 1;';
}

sub _return_value {
    my $self = shift;
    my ($slot_access) = @_;

    return '$return[0]';
}

no Moose::Role;

1;
