package Moose::Meta::Method::Accessor::Native::Array::reduce;
BEGIN {
  $Moose::Meta::Method::Accessor::Native::Array::reduce::AUTHORITY = 'cpan:STEVAN';
}
{
  $Moose::Meta::Method::Accessor::Native::Array::reduce::VERSION = '2.1005';
}

use strict;
use warnings;

use List::Util ();
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
                '"The argument passed to reduce must be a code reference"',
            ) . ';',
        '}',
    );
}

sub _return_value {
    my $self = shift;
    my ($slot_access) = @_;

    return 'List::Util::reduce { $_[0]->($a, $b) } @{ (' . $slot_access . ') }';
}

no Moose::Role;

1;
