package Moose::Meta::Method::Accessor::Native::Number::abs;
BEGIN {
  $Moose::Meta::Method::Accessor::Native::Number::abs::AUTHORITY = 'cpan:STEVAN';
}
{
  $Moose::Meta::Method::Accessor::Native::Number::abs::VERSION = '2.1005';
}

use strict;
use warnings;

use Moose::Role;

with 'Moose::Meta::Method::Accessor::Native::Writer';

sub _maximum_arguments { 0 }

sub _potential_value {
    my $self = shift;
    my ($slot_access) = @_;

    return 'abs(' . $slot_access . ')';
}

sub _inline_optimized_set_new_value {
    my $self = shift;
    my ($inv, $new, $slot_access) = @_;

    return $slot_access . ' = abs(' . $slot_access . ');';
}

no Moose::Role;

1;
