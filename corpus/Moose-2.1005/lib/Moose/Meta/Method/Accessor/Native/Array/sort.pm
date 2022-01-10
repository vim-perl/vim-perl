package Moose::Meta::Method::Accessor::Native::Array::sort;
BEGIN {
  $Moose::Meta::Method::Accessor::Native::Array::sort::AUTHORITY = 'cpan:STEVAN';
}
{
  $Moose::Meta::Method::Accessor::Native::Array::sort::VERSION = '2.1005';
}

use strict;
use warnings;

use Params::Util ();

use Moose::Role;

with 'Moose::Meta::Method::Accessor::Native::Reader';

sub _maximum_arguments { 1 }

sub _inline_check_arguments {
    my $self = shift;

    return (
        'if (@_ && !Params::Util::_CODELIKE($_[0])) {',
            $self->_inline_throw_error(
                '"The argument passed to sort must be a code reference"',
            ) . ';',
        '}',
    );
}

sub _return_value {
    my $self = shift;
    my ($slot_access) = @_;

    return '$_[0] '
             . '? sort { $_[0]->($a, $b) } @{ (' . $slot_access . ') } '
             . ': sort @{ (' . $slot_access . ') }';
}

no Moose::Role;

1;
