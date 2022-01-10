
package Moose::Meta::Instance;
BEGIN {
  $Moose::Meta::Instance::AUTHORITY = 'cpan:STEVAN';
}
{
  $Moose::Meta::Instance::VERSION = '2.1005';
}

use strict;
use warnings;

use Class::MOP::MiniTrait;

use base "Class::MOP::Instance";

Class::MOP::MiniTrait::apply(__PACKAGE__, 'Moose::Meta::Object::Trait');

1;

# ABSTRACT: The Moose Instance metaclass

__END__

=pod

=head1 NAME

Moose::Meta::Instance - The Moose Instance metaclass

=head1 VERSION

version 2.1005

=head1 SYNOPSIS

    # nothing to see here

=head1 DESCRIPTION

This class provides the low level data storage abstractions for
attributes.

Using this API directly in your own code violates encapsulation, and
we recommend that you use the appropriate APIs in
L<Moose::Meta::Class> and L<Moose::Meta::Attribute> instead. Those
APIs in turn call the methods in this class as appropriate.

At present, this is an empty subclass of L<Class::MOP::Instance>, so
you should see that class for all API details.

=head1 INHERITANCE

C<Moose::Meta::Instance> is a subclass of L<Class::MOP::Instance>.

=head1 BUGS

See L<Moose/BUGS> for details on reporting bugs.

=head1 AUTHOR

Moose is maintained by the Moose Cabal, along with the help of many contributors. See L<Moose/CABAL> and L<Moose/CONTRIBUTORS> for details.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Infinity Interactive, Inc..

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
