package Moose::Meta::Method::Accessor::Native::Array::join;
BEGIN {
  $Moose::Meta::Method::Accessor::Native::Array::join::AUTHORITY = 'cpan:STEVAN';
}
{
  $Moose::Meta::Method::Accessor::Native::Array::join::VERSION = '2.1005';
}

use strict;
use warnings;

use Moose::Util ();

use Moose::Role;

with 'Moose::Meta::Method::Accessor::Native::Reader';

sub _minimum_arguments { 1 }

sub _maximum_arguments { 1 }

sub _inline_check_arguments {
    my $self = shift;

    return (
        'if (!Moose::Util::_STRINGLIKE0($_[0])) {',
            $self->_inline_throw_error(
                '"The argument passed to join must be a string"',
            ) . ';',
        '}',
    );
}

sub _return_value {
    my $self = shift;
    my ($slot_access) = @_;

    return 'join $_[0], @{ (' . $slot_access . ') }';
}

no Moose::Role;

1;
