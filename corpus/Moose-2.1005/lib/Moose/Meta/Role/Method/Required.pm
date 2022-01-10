
package Moose::Meta::Role::Method::Required;
BEGIN {
  $Moose::Meta::Role::Method::Required::AUTHORITY = 'cpan:STEVAN';
}
{
  $Moose::Meta::Role::Method::Required::VERSION = '2.1005';
}

use strict;
use warnings;
use metaclass;

use overload '""'     => sub { shift->name },   # stringify to method name
             fallback => 1;

use base qw(Class::MOP::Object);

# This is not a Moose::Meta::Role::Method because it has no implementation, it
# is just a name

__PACKAGE__->meta->add_attribute('name' => (
    reader   => 'name',
    required => 1,
    Class::MOP::_definition_context(),
));

sub new { shift->_new(@_) }

1;

# ABSTRACT: A Moose metaclass for required methods in Roles

__END__

=pod

=head1 NAME

Moose::Meta::Role::Method::Required - A Moose metaclass for required methods in Roles

=head1 VERSION

version 2.1005

=head1 DESCRIPTION

=head1 INHERITANCE

C<Moose::Meta::Role::Method::Required> is a subclass of L<Class::MOP::Object>.
It is B<not> a subclass of C<Moose::Meta::Role::Method> since it does not
provide an implementation of the method.

=head1 METHODS

=over 4

=item B<< Moose::Meta::Role::Method::Required->new(%options) >>

This creates a new type constraint based on the provided C<%options>:

=over 8

=item * name

The method name. This is required.

=back

=item B<< $method->name >>

Returns the required method's name, as provided to the constructor.

=back

=head1 BUGS

See L<Moose/BUGS> for details on reporting bugs.

=head1 AUTHOR

Moose is maintained by the Moose Cabal, along with the help of many contributors. See L<Moose/CABAL> and L<Moose/CONTRIBUTORS> for details.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Infinity Interactive, Inc..

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
