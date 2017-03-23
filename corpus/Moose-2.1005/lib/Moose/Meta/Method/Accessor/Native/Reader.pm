package Moose::Meta::Method::Accessor::Native::Reader;
BEGIN {
  $Moose::Meta::Method::Accessor::Native::Reader::AUTHORITY = 'cpan:STEVAN';
}
{
  $Moose::Meta::Method::Accessor::Native::Reader::VERSION = '2.1005';
}

use strict;
use warnings;

use Moose::Role;

with 'Moose::Meta::Method::Accessor::Native';

requires '_return_value';

sub _generate_method {
    my $self = shift;

    my $inv         = '$self';
    my $slot_access = $self->_get_value($inv);

    return (
        'sub {',
            'my ' . $inv . ' = shift;',
            $self->_inline_curried_arguments,
            $self->_inline_reader_core($inv, $slot_access, @_),
        '}',
    );
}

sub _inline_reader_core {
    my $self = shift;
    my ($inv, $slot_access, @extra) = @_;

    return (
        $self->_inline_check_argument_count,
        $self->_inline_process_arguments($inv, $slot_access),
        $self->_inline_check_arguments,
        $self->_inline_check_lazy($inv, '$type_constraint', '$type_coercion', '$type_message'),
        $self->_inline_return_value($slot_access),
    );
}

sub _inline_process_arguments { return }

sub _inline_check_arguments { return }

no Moose::Role;

1;
