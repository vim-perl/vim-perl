
package Moose::Meta::Role::Method::Conflicting;
BEGIN {
  $Moose::Meta::Role::Method::Conflicting::AUTHORITY = 'cpan:STEVAN';
}
{
  $Moose::Meta::Role::Method::Conflicting::VERSION = '2.1005';
}

use strict;
use warnings;

use Moose::Util;

use base qw(Moose::Meta::Role::Method::Required);

__PACKAGE__->meta->add_attribute('roles' => (
    reader   => 'roles',
    required => 1,
    Class::MOP::_definition_context(),
));

sub roles_as_english_list {
    my $self = shift;
    Moose::Util::english_list( map { q{'} . $_ . q{'} } @{ $self->roles } );
}

1;

# ABSTRACT: A Moose metaclass for conflicting methods in Roles

__END__

=pod

=head1 NAME

Moose::Meta::Role::Method::Conflicting - A Moose metaclass for conflicting methods in Roles

=head1 VERSION

version 2.1005

=head1 DESCRIPTION

=head1 INHERITANCE

C<Moose::Meta::Role::Method::Conflicting> is a subclass of
L<Moose::Meta::Role::Method::Required>.

=head1 METHODS

=over 4

=item B<< Moose::Meta::Role::Method::Conflicting->new(%options) >>

This creates a new type constraint based on the provided C<%options>:

=over 8

=item * name

The method name. This is required.

=item * roles

The list of role names that generated the conflict. This is required.

=back

=item B<< $method->name >>

Returns the conflicting method's name, as provided to the constructor.

=item B<< $method->roles >>

Returns the roles that generated this conflicting method, as provided to the
constructor.

=item B<< $method->roles_as_english_list >>

Returns the roles that generated this conflicting method as an English list.

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
