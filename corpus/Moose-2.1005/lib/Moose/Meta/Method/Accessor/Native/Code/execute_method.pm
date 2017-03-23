package Moose::Meta::Method::Accessor::Native::Code::execute_method;
BEGIN {
  $Moose::Meta::Method::Accessor::Native::Code::execute_method::AUTHORITY = 'cpan:STEVAN';
}
{
  $Moose::Meta::Method::Accessor::Native::Code::execute_method::VERSION = '2.1005';
}

use strict;
use warnings;

use Moose::Role;

with 'Moose::Meta::Method::Accessor::Native::Reader';

sub _return_value {
    my $self = shift;
    my ($slot_access) = @_;

    return $slot_access . '->($self, @_)';
}

no Moose::Role;

1;
