package Moose::Meta::Role::Application::RoleSummation;
BEGIN {
  $Moose::Meta::Role::Application::RoleSummation::AUTHORITY = 'cpan:STEVAN';
}
{
  $Moose::Meta::Role::Application::RoleSummation::VERSION = '2.1005';
}

use strict;
use warnings;
use metaclass;

use Scalar::Util 'blessed';

use Moose::Meta::Role::Composite;

use base 'Moose::Meta::Role::Application';

__PACKAGE__->meta->add_attribute('role_params' => (
    reader  => 'role_params',
    default => sub { {} },
    Class::MOP::_definition_context(),
));

sub get_exclusions_for_role {
    my ($self, $role) = @_;
    $role = $role->name if blessed $role;
    my $excludes_key = exists $self->role_params->{$role}->{'-excludes'} ?
                           '-excludes' : 'excludes';
    if ($self->role_params->{$role} && defined $self->role_params->{$role}->{$excludes_key}) {
        if (ref $self->role_params->{$role}->{$excludes_key} eq 'ARRAY') {
            return $self->role_params->{$role}->{$excludes_key};
        }
        return [ $self->role_params->{$role}->{$excludes_key} ];
    }
    return [];
}

sub get_method_aliases_for_role {
    my ($self, $role) = @_;
    $role = $role->name if blessed $role;
    my $alias_key = exists $self->role_params->{$role}->{'-alias'} ?
                        '-alias' : 'alias';
    if ($self->role_params->{$role} && defined $self->role_params->{$role}->{$alias_key}) {
        return $self->role_params->{$role}->{$alias_key};
    }
    return {};
}

sub is_method_excluded {
    my ($self, $role, $method_name) = @_;
    foreach ($self->get_exclusions_for_role($role->name)) {
        return 1 if $_ eq $method_name;
    }
    return 0;
}

sub is_method_aliased {
    my ($self, $role, $method_name) = @_;
    exists $self->get_method_aliases_for_role($role->name)->{$method_name} ? 1 : 0
}

sub is_aliased_method {
    my ($self, $role, $method_name) = @_;
    my %aliased_names = reverse %{$self->get_method_aliases_for_role($role->name)};
    exists $aliased_names{$method_name} ? 1 : 0;
}

sub check_role_exclusions {
    my ($self, $c) = @_;

    my %excluded_roles;
    for my $role (@{ $c->get_roles }) {
        my $name = $role->name;

        for my $excluded ($role->get_excluded_roles_list) {
            push @{ $excluded_roles{$excluded} }, $name;
        }
    }

    foreach my $role (@{$c->get_roles}) {
        foreach my $excluded (keys %excluded_roles) {
            next unless $role->does_role($excluded);

            my @excluding = @{ $excluded_roles{$excluded} };

            require Moose;
            Moose->throw_error(sprintf "Conflict detected: Role%s %s exclude%s role '%s'", (@excluding == 1 ? '' : 's'), join(', ', @excluding), (@excluding == 1 ? 's' : ''), $excluded);
        }
    }

    $c->add_excluded_roles(keys %excluded_roles);
}

sub check_required_methods {
    my ($self, $c) = @_;

    my %all_required_methods =
        map { $_->name => $_ }
        map { $_->get_required_method_list }
        @{$c->get_roles};

    foreach my $role (@{$c->get_roles}) {
        foreach my $required (keys %all_required_methods) {

            delete $all_required_methods{$required}
                if $role->has_method($required)
                || $self->is_aliased_method($role, $required);
        }
    }

    $c->add_required_methods(values %all_required_methods);
}

sub check_required_attributes {

}

sub apply_attributes {
    my ($self, $c) = @_;

    my @all_attributes;

    for my $role ( @{ $c->get_roles } ) {
        push @all_attributes,
            map { $role->get_attribute($_) } $role->get_attribute_list;
    }

    my %seen;
    foreach my $attr (@all_attributes) {
        my $name = $attr->name;

        if ( exists $seen{$name} ) {
            next if $seen{$name}->is_same_as($attr);

            my $role1 = $seen{$name}->associated_role->name;
            my $role2 = $attr->associated_role->name;

            require Moose;
            Moose->throw_error(
                "We have encountered an attribute conflict with '$name' "
                    . "during role composition. "
                    . " This attribute is defined in both $role1 and $role2."
                    . " This is a fatal error and cannot be disambiguated." );
        }

        $seen{$name} = $attr;
    }

    foreach my $attr (@all_attributes) {
        $c->add_attribute( $attr->clone );
    }
}

sub apply_methods {
    my ($self, $c) = @_;

    my @all_methods = map {
        my $role     = $_;
        my $aliases  = $self->get_method_aliases_for_role($role);
        my %excludes = map { $_ => undef } @{ $self->get_exclusions_for_role($role) };
        (
            (map {
                exists $excludes{$_} ? () :
                +{
                    role   => $role,
                    name   => $_,
                    method => $role->get_method($_),
                }
            } map { $_->name }
              grep { !$_->isa('Class::MOP::Method::Meta') }
                   $role->_get_local_methods),
            (map {
                +{
                    role   => $role,
                    name   => $aliases->{$_},
                    method => $role->get_method($_),
                }
            } keys %$aliases)
        );
    } @{$c->get_roles};

    my (%seen, %conflicts, %method_map);
    foreach my $method (@all_methods) {
        next if $conflicts{$method->{name}};
        my $seen = $seen{$method->{name}};

        if ($seen) {
            if ($seen->{method}->body != $method->{method}->body) {
                $c->add_conflicting_method(
                    name  => $method->{name},
                    roles => [$method->{role}->name, $seen->{role}->name],
                );

                delete $method_map{$method->{name}};
                $conflicts{$method->{name}} = 1;
                next;
            }
        }

        $seen{$method->{name}}       = $method;
        $method_map{$method->{name}} = $method->{method};
    }

    $c->add_method($_ => $method_map{$_}) for keys %method_map;
}

sub apply_override_method_modifiers {
    my ($self, $c) = @_;

    my @all_overrides = map {
        my $role = $_;
        map {
            +{
                name   => $_,
                method => $role->get_override_method_modifier($_),
            }
        } $role->get_method_modifier_list('override');
    } @{$c->get_roles};

    my %seen;
    foreach my $override (@all_overrides) {
        if ( $c->has_method($override->{name}) ){
            require Moose;
            Moose->throw_error( "Role '" . $c->name . "' has encountered an 'override' method conflict " .
                                "during composition (A local method of the same name as been found). This " .
                                "is fatal error." )
        }
        if (exists $seen{$override->{name}}) {
            if ( $seen{$override->{name}} != $override->{method} ) {
                require Moose;
                Moose->throw_error( "We have encountered an 'override' method conflict during " .
                                    "composition (Two 'override' methods of the same name encountered). " .
                                    "This is fatal error.")
            }
        }
        $seen{$override->{name}} = $override->{method};
    }

    $c->add_override_method_modifier(
        $_->{name}, $_->{method}
    ) for @all_overrides;

}

sub apply_method_modifiers {
    my ($self, $modifier_type, $c) = @_;
    my $add = "add_${modifier_type}_method_modifier";
    my $get = "get_${modifier_type}_method_modifiers";
    foreach my $role (@{$c->get_roles}) {
        foreach my $method_name ($role->get_method_modifier_list($modifier_type)) {
            $c->$add(
                $method_name,
                $_
            ) foreach $role->$get($method_name);
        }
    }
}

1;

# ABSTRACT: Combine two or more roles

__END__

=pod

=head1 NAME

Moose::Meta::Role::Application::RoleSummation - Combine two or more roles

=head1 VERSION

version 2.1005

=head1 DESCRIPTION

Summation composes two traits, forming the union of non-conflicting
bindings and 'disabling' the conflicting bindings

=head2 METHODS

=over 4

=item B<new>

=item B<meta>

=item B<role_params>

=item B<get_exclusions_for_role>

=item B<get_method_aliases_for_role>

=item B<is_aliased_method>

=item B<is_method_aliased>

=item B<is_method_excluded>

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
