package Moose::Meta::Role::Composite;
BEGIN {
  $Moose::Meta::Role::Composite::AUTHORITY = 'cpan:STEVAN';
}
{
  $Moose::Meta::Role::Composite::VERSION = '2.1005';
}

use strict;
use warnings;
use metaclass;

use Class::Load qw(load_class);
use Scalar::Util 'blessed';

use base 'Moose::Meta::Role';

# NOTE:
# we need to override the ->name
# method from Class::MOP::Package
# since we don't have an actual
# package for this.
# - SL
__PACKAGE__->meta->add_attribute('name' => (
    reader => 'name',
    Class::MOP::_definition_context(),
));

# NOTE:
# Again, since we don't have a real
# package to store our methods in,
# we use a HASH ref instead.
# - SL
__PACKAGE__->meta->add_attribute('_methods' => (
    reader  => '_method_map',
    default => sub { {} },
    Class::MOP::_definition_context(),
));

__PACKAGE__->meta->add_attribute(
    'application_role_summation_class',
    reader  => 'application_role_summation_class',
    default => 'Moose::Meta::Role::Application::RoleSummation',
    Class::MOP::_definition_context(),
);

sub new {
    my ($class, %params) = @_;

    # the roles param is required ...
    foreach ( @{$params{roles}} ) {
        unless ( $_->isa('Moose::Meta::Role') ) {
            require Moose;
            Moose->throw_error("The list of roles must be instances of Moose::Meta::Role, not $_");
        }
    }

    my @composition_roles = map {
        $_->composition_class_roles
    } @{ $params{roles} };

    if (@composition_roles) {
        my $meta = Moose::Meta::Class->create_anon_class(
            superclasses => [ $class ],
            roles        => [ @composition_roles ],
            cache        => 1,
        );
        $class = $meta->name;
    }

    # and the name is created from the
    # roles if one has not been provided
    $params{name} ||= (join "|" => map { $_->name } @{$params{roles}});
    $class->_new(\%params);
}

# This is largely a copy of what's in Moose::Meta::Role (itself
# largely a copy of Class::MOP::Class). However, we can't actually
# call add_package_symbol, because there's no package into which to
# add the symbol.
sub add_method {
    my ($self, $method_name, $method) = @_;

    unless ( defined $method_name && $method_name ) {
        Moose->throw_error("You must define a method name");
    }

    my $body;
    if (blessed($method)) {
        $body = $method->body;
        if ($method->package_name ne $self->name) {
            $method = $method->clone(
                package_name => $self->name,
                name         => $method_name
            ) if $method->can('clone');
        }
    }
    else {
        $body = $method;
        $method = $self->wrap_method_body( body => $body, name => $method_name );
    }

    $self->_method_map->{$method_name} = $method;
}

sub get_method_list {
    my $self = shift;
    return keys %{ $self->_method_map };
}

sub _get_local_methods {
    my $self = shift;
    return values %{ $self->_method_map };
}

sub has_method {
    my ($self, $method_name) = @_;

    return exists $self->_method_map->{$method_name};
}

sub get_method {
    my ($self, $method_name) = @_;

    return $self->_method_map->{$method_name};
}

sub apply_params {
    my ($self, $role_params) = @_;
    load_class($self->application_role_summation_class);

    $self->application_role_summation_class->new(
        role_params => $role_params,
    )->apply($self);

    return $self;
}

sub reinitialize {
    my ( $class, $old_meta, @args ) = @_;

    Moose->throw_error(
        'Moose::Meta::Role::Composite instances can only be reinitialized from an existing metaclass instance'
        )
        if !blessed $old_meta
            || !$old_meta->isa('Moose::Meta::Role::Composite');

    my %existing_classes = map { $_ => $old_meta->$_() } qw(
        application_role_summation_class
    );

    return $old_meta->meta->clone_object( $old_meta, %existing_classes, @args );
}

1;

# ABSTRACT: An object to represent the set of roles

__END__

=pod

=head1 NAME

Moose::Meta::Role::Composite - An object to represent the set of roles

=head1 VERSION

version 2.1005

=head1 DESCRIPTION

A composite is a role that consists of a set of two or more roles.

The API of a composite role is almost identical to that of a regular
role.

=head1 INHERITANCE

C<Moose::Meta::Role::Composite> is a subclass of L<Moose::Meta::Role>.

=head2 METHODS

=over 4

=item B<< Moose::Meta::Role::Composite->new(%options) >>

This returns a new composite role object. It accepts the same
options as its parent class, with a few changes:

=over 8

=item * roles

This option is an array reference containing a list of
L<Moose::Meta::Role> object. This is a required option.

=item * name

If a name is not given, one is generated from the roles provided.

=item * apply_params(\%role_params)

Creates a new RoleSummation role application with C<%role_params> and applies
the composite role to it. The RoleSummation role application class used is
determined by the composite role's C<application_role_summation_class>
attribute.

=item * reinitialize($metaclass)

Like C<< Class::MOP::Package->reinitialize >>, but doesn't allow passing a
string with the package name, as there is no real package for composite roles.

=back

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
