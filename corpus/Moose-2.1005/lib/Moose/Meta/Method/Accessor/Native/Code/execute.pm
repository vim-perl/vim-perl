package Moose::Meta::Method::Accessor::Native::Code::execute;
BEGIN {
  $Moose::Meta::Method::Accessor::Native::Code::execute::AUTHORITY = 'cpan:STEVAN';
}
{
  $Moose::Meta::Method::Accessor::Native::Code::execute::VERSION = '2.1005';
}

use strict;
use warnings;

use Moose::Role;

with 'Moose::Meta::Method::Accessor::Native::Reader';

sub _return_value {
    my $self = shift;
    my ($slot_access) = @_;

    return $slot_access . '->(@_)';
}

no Moose::Role;

1;
