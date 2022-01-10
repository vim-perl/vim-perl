package Moose::Meta::Method::Accessor::Native::Array::accessor;
BEGIN {
  $Moose::Meta::Method::Accessor::Native::Array::accessor::AUTHORITY = 'cpan:STEVAN';
}
{
  $Moose::Meta::Method::Accessor::Native::Array::accessor::VERSION = '2.1005';
}

use strict;
use warnings;

use Moose::Role;

with 'Moose::Meta::Method::Accessor::Native::Array::set',
     'Moose::Meta::Method::Accessor::Native::Array::get';

sub _inline_process_arguments {
    my $self = shift;
    $self->Moose::Meta::Method::Accessor::Native::Array::get::_inline_process_arguments(@_);
}

sub _inline_check_arguments {
    my $self = shift;
    $self->Moose::Meta::Method::Accessor::Native::Array::get::_inline_check_arguments(@_);
}

sub _return_value {
    my $self = shift;
    $self->Moose::Meta::Method::Accessor::Native::Array::get::_return_value(@_);
}

sub _generate_method {
    my $self = shift;

    my $inv         = '$self';
    my $slot_access = $self->_get_value($inv);

    return (
        'sub {',
            'my ' . $inv . ' = shift;',
            $self->_inline_curried_arguments,
            $self->_inline_check_lazy($inv, '$type_constraint', '$type_coercion', '$type_message'),
            # get
            'if (@_ == 1) {',
                $self->_inline_check_var_is_valid_index('$_[0]'),
                $self->Moose::Meta::Method::Accessor::Native::Array::get::_inline_return_value($slot_access),
            '}',
            # set
            'else {',
                $self->_inline_writer_core($inv, $slot_access),
            '}',
        '}',
    );
}

sub _minimum_arguments { 1 }
sub _maximum_arguments { 2 }

no Moose::Role;

1;
