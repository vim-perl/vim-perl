
package MyMetaClass;

use strict;
use warnings;

use base 'Class::MOP::Class';

sub mymetaclass_attributes{
  my $self = shift;
  return grep { $_->isa("MyMetaClass::Attribute") }
    $self->get_all_attributes;
}

1;
