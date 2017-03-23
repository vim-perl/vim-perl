
package MOP::Point;

use strict;
use warnings;
use metaclass;

__PACKAGE__->meta->add_attribute('x' => (accessor => 'x', default => 10));
__PACKAGE__->meta->add_attribute('y' => (accessor => 'y'));

sub new {
    my $class = shift;
    $class->meta->new_object(@_);
}

sub clear {
    my $self = shift;
    $self->x(0);
    $self->y(0);
}

1;

__END__
