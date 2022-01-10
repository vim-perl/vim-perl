package Moose::Meta::Method::Accessor::Native::Array::natatime;
BEGIN {
  $Moose::Meta::Method::Accessor::Native::Array::natatime::AUTHORITY = 'cpan:STEVAN';
}
{
  $Moose::Meta::Method::Accessor::Native::Array::natatime::VERSION = '2.1005';
}

use strict;
use warnings;

use List::MoreUtils ();
use Params::Util ();

use Moose::Role;

with 'Moose::Meta::Method::Accessor::Native::Reader';

sub _minimum_arguments { 1 }

sub _maximum_arguments { 2 }

sub _inline_check_arguments {
    my $self = shift;

    return (
        'if (!defined($_[0]) || $_[0] !~ /^\d+$/) {',
            $self->_inline_throw_error(
                '"The n value passed to natatime must be an integer"',
            ) . ';',
        '}',
        'if (@_ == 2 && !Params::Util::_CODELIKE($_[1])) {',
            $self->_inline_throw_error(
                '"The second argument passed to natatime must be a code '
              . 'reference"',
            ) . ';',
        '}',
    );
}

sub _inline_return_value {
    my $self = shift;
    my ($slot_access) = @_;

    return (
        'my $iter = List::MoreUtils::natatime($_[0], @{ (' . $slot_access . ') });',
        'if ($_[1]) {',
            'while (my @vals = $iter->()) {',
                '$_[1]->(@vals);',
            '}',
        '}',
        'else {',
            'return $iter;',
        '}',
    );
}

# Not called, but needed to satisfy the Reader role
sub _return_value { }

no Moose::Role;

1;
