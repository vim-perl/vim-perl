use strict;
use warnings;

use Test::More;
use Test::Fatal;

{
    package MyClass;
    use Moose;

    sub DEMOLISH { }
}

my $object = MyClass->new;

# Removing the metaclass simulates the case where the metaclass object
# goes out of scope _before_ the object itself, which under normal
# circumstances only happens during global destruction.
Class::MOP::remove_metaclass_by_name('MyClass');

# The bug happened when DEMOLISHALL called
# Class::MOP::class_of($object) and did not get a metaclass object
# back.
is( exception { $object->DESTROY }, undef, 'can call DESTROY on an object without a metaclass object in the CMOP cache' );


MyClass->meta->make_immutable;
Class::MOP::remove_metaclass_by_name('MyClass');

# The bug didn't manifest for immutable objects, but this test should
# help us prevent it happening in the future.
is( exception { $object->DESTROY }, undef, 'can call DESTROY on an object without a metaclass object in the CMOP cache (immutable version)' );

done_testing;
