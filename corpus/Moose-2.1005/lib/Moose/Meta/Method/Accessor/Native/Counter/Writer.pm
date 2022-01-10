package Moose::Meta::Method::Accessor::Native::Counter::Writer;
BEGIN {
  $Moose::Meta::Method::Accessor::Native::Counter::Writer::AUTHORITY = 'cpan:STEVAN';
}
{
  $Moose::Meta::Method::Accessor::Native::Counter::Writer::VERSION = '2.1005';
}

use strict;
use warnings;

use Moose::Role;

with 'Moose::Meta::Method::Accessor::Native::Writer';

sub _constraint_must_be_checked {
    my $self = shift;

    my $attr = $self->associated_attribute;

    return $attr->has_type_constraint
        && ($attr->type_constraint->name =~ /^(?:Num|Int)$/
         || ($attr->should_coerce && $attr->type_constraint->has_coercion)
           );
}

no Moose::Role;

1;
