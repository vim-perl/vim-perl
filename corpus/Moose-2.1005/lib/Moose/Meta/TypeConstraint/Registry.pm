
package Moose::Meta::TypeConstraint::Registry;
BEGIN {
  $Moose::Meta::TypeConstraint::Registry::AUTHORITY = 'cpan:STEVAN';
}
{
  $Moose::Meta::TypeConstraint::Registry::VERSION = '2.1005';
}

use strict;
use warnings;
use metaclass;

use Scalar::Util 'blessed';

use base 'Class::MOP::Object';

__PACKAGE__->meta->add_attribute('parent_registry' => (
    reader    => 'get_parent_registry',
    writer    => 'set_parent_registry',
    predicate => 'has_parent_registry',
    Class::MOP::_definition_context(),
));

__PACKAGE__->meta->add_attribute('type_constraints' => (
    reader  => 'type_constraints',
    default => sub { {} },
    Class::MOP::_definition_context(),
));

sub new {
    my $class = shift;
    my $self  = $class->_new(@_);
    return $self;
}

sub has_type_constraint {
    my ($self, $type_name) = @_;
    ($type_name and exists $self->type_constraints->{$type_name}) ? 1 : 0
}

sub get_type_constraint {
    my ($self, $type_name) = @_;
    return unless defined $type_name;
    $self->type_constraints->{$type_name}
}

sub add_type_constraint {
    my ($self, $type) = @_;

    unless ( $type && blessed $type && $type->isa('Moose::Meta::TypeConstraint') ) {
        require Moose;
        Moose->throw_error("No type supplied / type is not a valid type constraint");
    }

    $self->type_constraints->{$type->name} = $type;
}

sub find_type_constraint {
    my ($self, $type_name) = @_;
    return $self->get_type_constraint($type_name)
        if $self->has_type_constraint($type_name);
    return $self->get_parent_registry->find_type_constraint($type_name)
        if $self->has_parent_registry;
    return;
}

1;

# ABSTRACT: registry for type constraints

__END__

=pod

=head1 NAME

Moose::Meta::TypeConstraint::Registry - registry for type constraints

=head1 VERSION

version 2.1005

=head1 DESCRIPTION

This class is a registry that maps type constraint names to
L<Moose::Meta::TypeConstraint> objects.

Currently, it is only used internally by
L<Moose::Util::TypeConstraints>, which creates a single global
registry.

=head1 INHERITANCE

C<Moose::Meta::TypeConstraint::Registry> is a subclass of
L<Class::MOP::Object>.

=head1 METHODS

=over 4

=item B<< Moose::Meta::TypeConstraint::Registry->new(%options) >>

This creates a new registry object based on the provided C<%options>:

=over 8

=item * parent_registry

This is an optional L<Moose::Meta::TypeConstraint::Registry>
object.

=item * type_constraints

This is hash reference of type names to type objects. This is
optional. Constraints can be added to the registry after it is
created.

=back

=item B<< $registry->get_parent_registry >>

Returns the registry's parent registry, if it has one.

=item B<< $registry->has_parent_registry >>

Returns true if the registry has a parent.

=item B<< $registry->set_parent_registry($registry) >>

Sets the parent registry.

=item B<< $registry->get_type_constraint($type_name) >>

This returns the L<Moose::Meta::TypeConstraint> object from the
registry for the given name, if one exists.

=item B<< $registry->has_type_constraint($type_name) >>

Returns true if the registry has a type of the given name.

=item B<< $registry->add_type_constraint($type) >>

Adds a new L<Moose::Meta::TypeConstraint> object to the registry.

=item B<< $registry->find_type_constraint($type_name) >>

This method looks in the current registry for the named type. If the
type is not found, then this method will look in the registry's
parent, if it has one.

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
