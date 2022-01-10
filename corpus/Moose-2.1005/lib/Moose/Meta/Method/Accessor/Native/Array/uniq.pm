package Moose::Meta::Method::Accessor::Native::Array::uniq;
BEGIN {
  $Moose::Meta::Method::Accessor::Native::Array::uniq::AUTHORITY = 'cpan:STEVAN';
}
{
  $Moose::Meta::Method::Accessor::Native::Array::uniq::VERSION = '2.1005';
}

use strict;
use warnings;

use List::MoreUtils ();

use Moose::Role;

with 'Moose::Meta::Method::Accessor::Native::Reader';

sub _maximum_arguments { 0 }

sub _return_value {
    my $self = shift;
    my ($slot_access) = @_;

    return 'List::MoreUtils::uniq @{ (' . $slot_access . ') }';
}

no Moose::Role;

1;
