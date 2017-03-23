package Moose::Util::MetaRole;
BEGIN {
  $Moose::Util::MetaRole::AUTHORITY = 'cpan:STEVAN';
}
{
  $Moose::Util::MetaRole::VERSION = '2.1005';
}

use strict;
use warnings;
use Scalar::Util 'blessed';

use Carp qw( croak );
use List::MoreUtils qw( all );
use List::Util qw( first );
use Moose::Deprecated;
use Scalar::Util qw( blessed );

sub apply_metaroles {
    my %args = @_;

    my $for = _metathing_for( $args{for} );

    if ( $for->isa('Moose::Meta::Role') ) {
        return _make_new_metaclass( $for, $args{role_metaroles}, 'role' );
    }
    else {
        return _make_new_metaclass( $for, $args{class_metaroles}, 'class' );
    }
}

sub _metathing_for {
    my $passed = shift;

    my $found
        = blessed $passed
        ? $passed
        : Class::MOP::class_of($passed);

    return $found
        if defined $found
            && blessed $found
            && (   $found->isa('Moose::Meta::Role')
                || $found->isa('Moose::Meta::Class') );

    local $Carp::CarpLevel = $Carp::CarpLevel + 1;

    my $error_start
        = 'When using Moose::Util::MetaRole, you must pass a Moose class name,'
        . ' role name, metaclass object, or metarole object.';

    if ( defined $found && blessed $found ) {
        croak $error_start
            . " You passed $passed, and we resolved this to a "
            . ( blessed $found )
            . ' object.';
    }

    if ( defined $passed && !defined $found ) {
        croak $error_start
            . " You passed $passed, and this did not resolve to a metaclass or metarole."
            . ' Maybe you need to call Moose->init_meta to initialize the metaclass first?';
    }

    if ( !defined $passed ) {
        croak $error_start
            . " You passed an undef."
            . ' Maybe you need to call Moose->init_meta to initialize the metaclass first?';
    }
}

sub _make_new_metaclass {
    my $for     = shift;
    my $roles   = shift;
    my $primary = shift;

    return $for unless keys %{$roles};

    my $new_metaclass
        = exists $roles->{$primary}
        ? _make_new_class( ref $for, $roles->{$primary} )
        : blessed $for;

    my %classes;

    for my $key ( grep { $_ ne $primary } keys %{$roles} ) {
        my $attr = first {$_}
            map { $for->meta->find_attribute_by_name($_) } (
            $key . '_metaclass',
            $key . '_class'
        );

        my $reader = $attr->get_read_method;

        $classes{ $attr->init_arg }
            = _make_new_class( $for->$reader(), $roles->{$key} );
    }

    my $new_meta = $new_metaclass->reinitialize( $for, %classes );

    return $new_meta;
}

sub apply_base_class_roles {
    my %args = @_;

    my $meta = _metathing_for( $args{for} || $args{for_class} );
    croak 'You can only apply base class roles to a Moose class, not a role.'
        if $meta->isa('Moose::Meta::Role');

    my $new_base = _make_new_class(
        $meta->name,
        $args{roles},
        [ $meta->superclasses() ],
    );

    $meta->superclasses($new_base)
        if $new_base ne $meta->name();
}

sub _make_new_class {
    my $existing_class = shift;
    my $roles          = shift;
    my $superclasses   = shift || [$existing_class];

    return $existing_class unless $roles;

    my $meta = Class::MOP::Class->initialize($existing_class);

    return $existing_class
        if $meta->can('does_role') && all  { $meta->does_role($_) }
                                      grep { !ref $_ } @{$roles};

    return Moose::Meta::Class->create_anon_class(
        superclasses => $superclasses,
        roles        => $roles,
        cache        => 1,
    )->name();
}

1;

# ABSTRACT: Apply roles to any metaclass, as well as the object base class

__END__

=pod

=head1 NAME

Moose::Util::MetaRole - Apply roles to any metaclass, as well as the object base class

=head1 VERSION

version 2.1005

=head1 SYNOPSIS

  package MyApp::Moose;

  use Moose ();
  use Moose::Exporter;
  use Moose::Util::MetaRole;

  use MyApp::Role::Meta::Class;
  use MyApp::Role::Meta::Method::Constructor;
  use MyApp::Role::Object;

  Moose::Exporter->setup_import_methods( also => 'Moose' );

  sub init_meta {
      shift;
      my %args = @_;

      Moose->init_meta(%args);

      Moose::Util::MetaRole::apply_metaroles(
          for             => $args{for_class},
          class_metaroles => {
              class => => ['MyApp::Role::Meta::Class'],
              constructor => ['MyApp::Role::Meta::Method::Constructor'],
          },
      );

      Moose::Util::MetaRole::apply_base_class_roles(
          for   => $args{for_class},
          roles => ['MyApp::Role::Object'],
      );

      return $args{for_class}->meta();
  }

=head1 DESCRIPTION

This utility module is designed to help authors of Moose extensions
write extensions that are able to cooperate with other Moose
extensions. To do this, you must write your extensions as roles, which
can then be dynamically applied to the caller's metaclasses.

This module makes sure to preserve any existing superclasses and roles
already set for the meta objects, which means that any number of
extensions can apply roles in any order.

=head1 USAGE

The easiest way to use this module is through L<Moose::Exporter>, which can
generate the appropriate C<init_meta> method for you, and make sure it is
called when imported.

=head1 FUNCTIONS

This module provides two functions.

=head2 apply_metaroles( ... )

This function will apply roles to one or more metaclasses for the specified
class. It will return a new metaclass object for the class or role passed in
the "for" parameter.

It accepts the following parameters:

=over 4

=item * for => $name

This specifies the class or for which to alter the meta classes. This can be a
package name, or an appropriate meta-object (a L<Moose::Meta::Class> or
L<Moose::Meta::Role>).

=item * class_metaroles => \%roles

This is a hash reference specifying which metaroles will be applied to the
class metaclass and its contained metaclasses and helper classes.

Each key should in turn point to an array reference of role names.

It accepts the following keys:

=over 8

=item class

=item attribute

=item method

=item wrapped_method

=item instance

=item constructor

=item destructor

=item error

=back

=item * role_metaroles => \%roles

This is a hash reference specifying which metaroles will be applied to the
role metaclass and its contained metaclasses and helper classes.

It accepts the following keys:

=over 8

=item role

=item attribute

=item method

=item required_method

=item conflicting_method

=item application_to_class

=item application_to_role

=item application_to_instance

=item application_role_summation

=item applied_attribute

=back

=back

=head2 apply_base_class_roles( for => $class, roles => \@roles )

This function will apply the specified roles to the object's base class.

=head1 BUGS

See L<Moose/BUGS> for details on reporting bugs.

=head1 AUTHOR

Moose is maintained by the Moose Cabal, along with the help of many contributors. See L<Moose/CABAL> and L<Moose/CONTRIBUTORS> for details.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Infinity Interactive, Inc..

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
