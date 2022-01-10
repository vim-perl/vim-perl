package Moose::Meta::Method::Accessor::Native::Array::count;
BEGIN {
  $Moose::Meta::Method::Accessor::Native::Array::count::AUTHORITY = 'cpan:STEVAN';
}
{
  $Moose::Meta::Method::Accessor::Native::Array::count::VERSION = '2.1005';
}

use strict;
use warnings;

use Moose::Role;

with 'Moose::Meta::Method::Accessor::Native::Reader';

sub _maximum_arguments { 0 }

sub _return_value {
    my $self = shift;
    my ($slot_access) = @_;

    return 'scalar @{ (' . $slot_access . ') }';
}

no Moose::Role;

1;
