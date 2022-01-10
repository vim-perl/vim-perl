package Moose::Meta::Attribute::Custom::Trait::Bar;

sub register_implementation { 'My::Trait::Bar' }


package My::Trait::Bar;

use Moose::Role;

1;
