package Moose::Meta::Method::Accessor::Native::Hash::delete;
BEGIN {
  $Moose::Meta::Method::Accessor::Native::Hash::delete::AUTHORITY = 'cpan:STEVAN';
}
{
  $Moose::Meta::Method::Accessor::Native::Hash::delete::VERSION = '2.1005';
}

use strict;
use warnings;

use Moose::Role;

with 'Moose::Meta::Method::Accessor::Native::Hash::Writer';

sub _adds_members { 0 }

sub _potential_value {
    my $self = shift;
    my ($slot_access) = @_;

    return '(do { '
             . 'my %potential = %{ (' . $slot_access . ') }; '
             . '@return = delete @potential{@_}; '
             . '\%potential; '
         . '})';
}

sub _inline_optimized_set_new_value {
    my $self = shift;
    my ($inv, $new, $slot_access) = @_;

    return '@return = delete @{ (' . $slot_access . ') }{@_};';
}

sub _return_value {
    my $self = shift;
    my ($slot_access) = @_;

    return 'wantarray ? @return : $return[-1]';
}

no Moose::Role;

1;
