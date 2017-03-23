package Moose::Meta::Method::Accessor::Native::Hash::get;
BEGIN {
  $Moose::Meta::Method::Accessor::Native::Hash::get::AUTHORITY = 'cpan:STEVAN';
}
{
  $Moose::Meta::Method::Accessor::Native::Hash::get::VERSION = '2.1005';
}

use strict;
use warnings;

use Scalar::Util qw( looks_like_number );

use Moose::Role;

with 'Moose::Meta::Method::Accessor::Native::Reader',
     'Moose::Meta::Method::Accessor::Native::Hash';

sub _minimum_arguments { 1 }

sub _inline_check_arguments {
    my $self = shift;

    return (
        'for (@_) {',
            $self->_inline_check_var_is_valid_key('$_'),
        '}',
    );
}

sub _return_value {
    my $self = shift;
    my ($slot_access) = @_;

    return '@_ > 1 '
             . '? @{ (' . $slot_access . ') }{@_} '
             . ': ' . $slot_access . '->{$_[0]}';
}

no Moose::Role;

1;
