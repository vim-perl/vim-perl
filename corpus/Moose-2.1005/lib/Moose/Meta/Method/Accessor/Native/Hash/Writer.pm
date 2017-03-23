package Moose::Meta::Method::Accessor::Native::Hash::Writer;
BEGIN {
  $Moose::Meta::Method::Accessor::Native::Hash::Writer::AUTHORITY = 'cpan:STEVAN';
}
{
  $Moose::Meta::Method::Accessor::Native::Hash::Writer::VERSION = '2.1005';
}

use strict;
use warnings;

use Class::MOP::MiniTrait;

use Moose::Role;

with 'Moose::Meta::Method::Accessor::Native::Writer',
     'Moose::Meta::Method::Accessor::Native::Hash',
     'Moose::Meta::Method::Accessor::Native::Collection';

sub _inline_coerce_new_values {
    my $self = shift;
    $self->Moose::Meta::Method::Accessor::Native::Collection::_inline_coerce_new_values(@_);
}

sub _new_values { '@values' }

sub _copy_old_value {
    my $self = shift;
    my ($slot_access) = @_;

    return '{ %{ (' . $slot_access . ') } }';
}

no Moose::Role;

1;
