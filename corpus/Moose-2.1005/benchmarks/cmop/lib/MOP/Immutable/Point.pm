
package MOP::Immutable::Point;

use strict;
use warnings;
use metaclass;

__PACKAGE__->meta->add_attribute('x' => (accessor => 'x', default => 10));
__PACKAGE__->meta->add_attribute('y' => (accessor => 'y'));

sub clear {
    my $self = shift;
    $self->x(0);
    $self->y(0);
}

__PACKAGE__->meta->make_immutable;

1;

__END__
