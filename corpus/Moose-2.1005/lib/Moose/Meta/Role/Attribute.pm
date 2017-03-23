package Moose::Meta::Role::Attribute;
BEGIN {
  $Moose::Meta::Role::Attribute::AUTHORITY = 'cpan:STEVAN';
}
{
  $Moose::Meta::Role::Attribute::VERSION = '2.1005';
}

use strict;
use warnings;

use Carp 'confess';
use List::MoreUtils 'all';
use Scalar::Util 'blessed', 'weaken';

use base 'Moose::Meta::Mixin::AttributeCore', 'Class::MOP::Object';

__PACKAGE__->meta->add_attribute(
    'metaclass' => (
        reader => 'metaclass',
        Class::MOP::_definition_context(),
    )
);

__PACKAGE__->meta->add_attribute(
    'associated_role' => (
        reader => 'associated_role',
        Class::MOP::_definition_context(),
    )
);

__PACKAGE__->meta->add_attribute(
    '_original_role' => (
        reader => '_original_role',
        Class::MOP::_definition_context(),
    )
);

__PACKAGE__->meta->add_attribute(
    'is' => (
        reader => 'is',
        Class::MOP::_definition_context(),
    )
);

__PACKAGE__->meta->add_attribute(
    'original_options' => (
        reader => 'original_options',
        Class::MOP::_definition_context(),
    )
);

sub new {
    my ( $class, $name, %options ) = @_;

    (defined $name)
        || confess "You must provide a name for the attribute";

    my $role = delete $options{_original_role};

    return bless {
        name             => $name,
        original_options => \%options,
        _original_role   => $role,
        %options,
    }, $class;
}

sub attach_to_role {
    my ( $self, $role ) = @_;

    ( blessed($role) && $role->isa('Moose::Meta::Role') )
        || confess
        "You must pass a Moose::Meta::Role instance (or a subclass)";

    weaken( $self->{'associated_role'} = $role );
}

sub original_role {
    my $self = shift;

    return $self->_original_role || $self->associated_role;
}

sub attribute_for_class {
    my $self = shift;

    my $metaclass = $self->original_role->applied_attribute_metaclass;

    return $metaclass->interpolate_class_and_new(
        $self->name => %{ $self->original_options } );
}

sub clone {
    my $self = shift;

    my $role = $self->original_role;

    return ( ref $self )->new(
        $self->name,
        %{ $self->original_options },
        _original_role => $role,
    );
}

sub is_same_as {
    my $self = shift;
    my $attr = shift;

    my $self_options = $self->original_options;
    my $other_options = $attr->original_options;

    return 0
        unless ( join q{|}, sort keys %{$self_options} ) eq ( join q{|}, sort keys %{$other_options} );

    for my $key ( keys %{$self_options} ) {
        return 0 if defined $self_options->{$key} && ! defined $other_options->{$key};
        return 0 if ! defined $self_options->{$key} && defined $other_options->{$key};

        next if all { ! defined } $self_options->{$key}, $other_options->{$key};

        return 0 unless $self_options->{$key} eq $other_options->{$key};
    }

    return 1;
}

1;

# ABSTRACT: The Moose attribute metaclass for Roles

__END__

=pod

=head1 NAME

Moose::Meta::Role::Attribute - The Moose attribute metaclass for Roles

=head1 VERSION

version 2.1005

=head1 DESCRIPTION

This class implements the API for attributes in roles. Attributes in roles are
more like attribute prototypes than full blown attributes. While they are
introspectable, they have very little behavior.

=head1 METHODS

This class provides the following methods:

=over 4

=item B<< Moose::Meta::Role::Attribute->new(...) >>

This method accepts all the options that would be passed to the constructor
for L<Moose::Meta::Attribute>.

=item B<< $attr->metaclass >>

=item B<< $attr->is >>

Returns the option as passed to the constructor.

=item B<< $attr->associated_role >>

Returns the L<Moose::Meta::Role> to which this attribute belongs, if any.

=item B<< $attr->original_role >>

Returns the L<Moose::Meta::Role> in which this attribute was first
defined. This may not be the same as the value of C<associated_role()> for
attributes in a composite role, or when one role consumes other roles.

=item B<< $attr->original_options >>

Returns a hash reference of options passed to the constructor. This is used
when creating a L<Moose::Meta::Attribute> object from this object.

=item B<< $attr->attach_to_role($role) >>

Attaches the attribute to the given L<Moose::Meta::Role>.

=item B<< $attr->attribute_for_class($metaclass) >>

Given an attribute metaclass name, this method calls C<<
$metaclass->interpolate_class_and_new >> to construct an attribute object
which can be added to a L<Moose::Meta::Class>.

=item B<< $attr->clone >>

Creates a new object identical to the object on which the method is called.

=item B<< $attr->is_same_as($other_attr) >>

Compares two role attributes and returns true if they are identical.

=back

In addition, this class implements all informational predicates implements by
L<Moose::Meta::Attribute> (and L<Class::MOP::Attribute>).

=head1 BUGS

See L<Moose/BUGS> for details on reporting bugs.

=head1 AUTHOR

Moose is maintained by the Moose Cabal, along with the help of many contributors. See L<Moose/CABAL> and L<Moose/CONTRIBUTORS> for details.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Infinity Interactive, Inc..

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
