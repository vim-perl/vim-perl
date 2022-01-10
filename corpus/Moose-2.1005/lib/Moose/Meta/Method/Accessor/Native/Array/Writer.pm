package Moose::Meta::Method::Accessor::Native::Array::Writer;
BEGIN {
  $Moose::Meta::Method::Accessor::Native::Array::Writer::AUTHORITY = 'cpan:STEVAN';
}
{
  $Moose::Meta::Method::Accessor::Native::Array::Writer::VERSION = '2.1005';
}

use strict;
use warnings;

use Moose::Role;

with 'Moose::Meta::Method::Accessor::Native::Writer',
     'Moose::Meta::Method::Accessor::Native::Array',
     'Moose::Meta::Method::Accessor::Native::Collection';

sub _inline_coerce_new_values {
    my $self = shift;
    $self->Moose::Meta::Method::Accessor::Native::Collection::_inline_coerce_new_values(@_);
}

sub _new_members { '@_' }

sub _copy_old_value {
    my $self = shift;
    my ($slot_access) = @_;

    return '[ @{(' . $slot_access . ')} ]';
}

1;
