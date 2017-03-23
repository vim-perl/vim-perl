
package MOP::Immutable::Point3D;

use strict;
use warnings;
use metaclass;

use base 'MOP::Point';

__PACKAGE__->meta->add_attribute('z' => (accessor => 'z'));

sub clear {
    my $self = shift;
    $self->SUPER::clear();
    $self->z(0);
}

__PACKAGE__->meta->make_immutable;

1;

__END__
