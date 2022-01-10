package Moose::Meta::Method::Accessor::Native::Array::unshift;
BEGIN {
  $Moose::Meta::Method::Accessor::Native::Array::unshift::AUTHORITY = 'cpan:STEVAN';
}
{
  $Moose::Meta::Method::Accessor::Native::Array::unshift::VERSION = '2.1005';
}

use strict;
use warnings;

use Moose::Role;

with 'Moose::Meta::Method::Accessor::Native::Array::Writer';

sub _adds_members { 1 }

sub _potential_value {
    my $self = shift;
    my ($slot_access) = @_;

    return '[ @_, @{ (' . $slot_access . ') } ]';
}

sub _inline_optimized_set_new_value {
    my $self = shift;
    my ($inv, $new, $slot_access) = @_;

    return 'unshift @{ (' . $slot_access . ') }, @_;';
}

sub _return_value {
    my $self = shift;
    my ($slot_access) = @_;

    return 'scalar @{ (' . $slot_access . ') }';
}

no Moose::Role;

1;
