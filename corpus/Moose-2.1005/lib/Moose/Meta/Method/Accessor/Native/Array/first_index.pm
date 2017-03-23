package Moose::Meta::Method::Accessor::Native::Array::first_index;
BEGIN {
  $Moose::Meta::Method::Accessor::Native::Array::first_index::AUTHORITY = 'cpan:STEVAN';
}
{
  $Moose::Meta::Method::Accessor::Native::Array::first_index::VERSION = '2.1005';
}

use strict;
use warnings;

use List::MoreUtils ();
use Params::Util ();

use Moose::Role;

with 'Moose::Meta::Method::Accessor::Native::Reader';

sub _minimum_arguments { 1 }

sub _maximum_arguments { 1 }

sub _inline_check_arguments {
    my $self = shift;

    return (
        'if (!Params::Util::_CODELIKE($_[0])) {',
            $self->_inline_throw_error(
                '"The argument passed to first_index must be a code reference"',
            ) . ';',
        '}',
    );
}

sub _return_value {
    my $self = shift;
    my ($slot_access) = @_;

    return '&List::MoreUtils::first_index($_[0], @{ (' . $slot_access . ') })';
}

no Moose::Role;

1;
