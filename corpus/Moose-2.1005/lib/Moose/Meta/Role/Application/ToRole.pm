package Moose::Meta::Role::Application::ToRole;
BEGIN {
  $Moose::Meta::Role::Application::ToRole::AUTHORITY = 'cpan:STEVAN';
}
{
  $Moose::Meta::Role::Application::ToRole::VERSION = '2.1005';
}

use strict;
use warnings;
use metaclass;

use Scalar::Util    'blessed';

use base 'Moose::Meta::Role::Application';

sub apply {
    my ($self, $role1, $role2) = @_;
    $self->SUPER::apply($role1, $role2);
    $role2->add_role($role1);
}

sub check_role_exclusions {
    my ($self, $role1, $role2) = @_;
    if ( $role2->excludes_role($role1->name) ) {
        require Moose;
        Moose->throw_error("Conflict detected: " . $role2->name . " excludes role '" . $role1->name . "'");
    }
    foreach my $excluded_role_name ($role1->get_excluded_roles_list) {
        if ( $role2->does_role($excluded_role_name) ) {
            require Moose;
            Moose->throw_error("The role " . $role2->name . " does the excluded role '$excluded_role_name'");
        }
        $role2->add_excluded_roles($excluded_role_name);
    }
}

sub check_required_methods {
    my ($self, $role1, $role2) = @_;
    foreach my $required_method ($role1->get_required_method_list) {
        my $required_method_name = $required_method->name;

        next if $self->is_aliased_method($required_method_name);

        $role2->add_required_methods($required_method)
            unless $role2->find_method_by_name($required_method_name);
    }
}

sub check_required_attributes {

}

sub apply_attributes {
    my ($self, $role1, $role2) = @_;
    foreach my $attribute_name ($role1->get_attribute_list) {
        # it if it has one already
        if ($role2->has_attribute($attribute_name) &&
            # make sure we haven't seen this one already too
            $role2->get_attribute($attribute_name) != $role1->get_attribute($attribute_name)) {

            my $role2_name = $role2->name;

            require Moose;
            Moose->throw_error( "Role '"
                    . $role1->name
                    . "' has encountered an attribute conflict"
                    . " while being composed into '$role2_name'."
                    . " This is a fatal error and cannot be disambiguated."
                    . " The conflicting attribute is named '$attribute_name'." );
        }
        else {
            $role2->add_attribute(
                $role1->get_attribute($attribute_name)->clone
            );
        }
    }
}

sub apply_methods {
    my ( $self, $role1, $role2 ) = @_;
    foreach my $method ( $role1->_get_local_methods ) {

        my $method_name = $method->name;

        next if $method->isa('Class::MOP::Method::Meta');

        unless ( $self->is_method_excluded($method_name) ) {

            my $role2_method = $role2->get_method($method_name);
            if (   $role2_method
                && $role2_method->body != $method->body ) {

                # method conflicts between roles used to result in the method
                # becoming a requirement but now are permitted just like
                # for classes, hence no code in this branch anymore.
            }
            else {
                $role2->add_method(
                    $method_name,
                    $method,
                );
            }
        }

        next unless $self->is_method_aliased($method_name);

        my $aliased_method_name = $self->get_method_aliases->{$method_name};

        my $role2_method = $role2->get_method($aliased_method_name);

        if (   $role2_method
            && $role2_method->body != $method->body ) {

            require Moose;
            Moose->throw_error(
                "Cannot create a method alias if a local method of the same name exists"
            );
        }

        $role2->add_method(
            $aliased_method_name,
            $role1->get_method($method_name)
        );

        if ( !$role2->has_method($method_name) ) {
            $role2->add_required_methods($method_name)
                unless $self->is_method_excluded($method_name);
        }
    }
}

sub apply_override_method_modifiers {
    my ($self, $role1, $role2) = @_;
    foreach my $method_name ($role1->get_method_modifier_list('override')) {
        # it if it has one already then ...
        if ($role2->has_method($method_name)) {
            # if it is being composed into another role
            # we have a conflict here, because you cannot
            # combine an overridden method with a locally
            # defined one
            require Moose;
            Moose->throw_error("Role '" . $role1->name . "' has encountered an 'override' method conflict " .
                    "during composition (A local method of the same name as been found). This " .
                    "is fatal error.");
        }
        else {
            # if we are a role, we need to make sure
            # we don't have a conflict with the role
            # we are composing into
            if ($role2->has_override_method_modifier($method_name) &&
                $role2->get_override_method_modifier($method_name) != $role2->get_override_method_modifier($method_name)) {

                require Moose;
                Moose->throw_error("Role '" . $role1->name . "' has encountered an 'override' method conflict " .
                        "during composition (Two 'override' methods of the same name encountered). " .
                        "This is fatal error.");
            }
            else {
                # if there is no conflict,
                # just add it to the role
                $role2->add_override_method_modifier(
                    $method_name,
                    $role1->get_override_method_modifier($method_name)
                );
            }
        }
    }
}

sub apply_method_modifiers {
    my ($self, $modifier_type, $role1, $role2) = @_;
    my $add = "add_${modifier_type}_method_modifier";
    my $get = "get_${modifier_type}_method_modifiers";
    foreach my $method_name ($role1->get_method_modifier_list($modifier_type)) {
        $role2->$add(
            $method_name,
            $_
        ) foreach $role1->$get($method_name);
    }
}


1;

# ABSTRACT: Compose a role into another role

__END__

=pod

=head1 NAME

Moose::Meta::Role::Application::ToRole - Compose a role into another role

=head1 VERSION

version 2.1005

=head1 DESCRIPTION

=head2 METHODS

=over 4

=item B<new>

=item B<meta>

=item B<apply>

=item B<check_role_exclusions>

=item B<check_required_methods>

=item B<check_required_attributes>

=item B<apply_attributes>

=item B<apply_methods>

=item B<apply_method_modifiers>

=item B<apply_override_method_modifiers>

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
