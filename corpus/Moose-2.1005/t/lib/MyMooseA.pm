package MyMooseA;

use Moose;

has 'b' => (is => 'rw', isa => 'MyMooseB');

1;