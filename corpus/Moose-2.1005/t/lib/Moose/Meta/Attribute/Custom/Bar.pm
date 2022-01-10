package Moose::Meta::Attribute::Custom::Bar;

sub register_implementation { 'My::Bar' }


package My::Bar;

use Moose::Role;

1;
