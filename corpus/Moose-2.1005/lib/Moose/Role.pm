package Moose::Role;
BEGIN {
  $Moose::Role::AUTHORITY = 'cpan:STEVAN';
}
{
  $Moose::Role::VERSION = '2.1005';
}
use strict;
use warnings;

use Scalar::Util 'blessed';
use Carp         'croak';
use Class::Load  'is_class_loaded';

use Sub::Exporter;

use Moose       ();
use Moose::Util ();

use Moose::Exporter;
use Moose::Meta::Role;
use Moose::Util::TypeConstraints;

sub extends {
    croak "Roles do not support 'extends' (you can use 'with' to specialize a role)";
}

sub with {
    Moose::Util::apply_all_roles( shift, @_ );
}

sub requires {
    my $meta = shift;
    croak "Must specify at least one method" unless @_;
    $meta->add_required_methods(@_);
}

sub excludes {
    my $meta = shift;
    croak "Must specify at least one role" unless @_;
    $meta->add_excluded_roles(@_);
}

sub has {
    my $meta = shift;
    my $name = shift;
    croak 'Usage: has \'name\' => ( key => value, ... )' if @_ == 1;
    my %context = Moose::Util::_caller_info;
    $context{context} = 'has declaration';
    $context{type} = 'role';
    my %options = ( definition_context => \%context, @_ );
    my $attrs = ( ref($name) eq 'ARRAY' ) ? $name : [ ($name) ];
    $meta->add_attribute( $_, %options ) for @$attrs;
}

sub _add_method_modifier {
    my $type = shift;
    my $meta = shift;

    if ( ref($_[0]) eq 'Regexp' ) {
        croak "Roles do not currently support regex "
            . " references for $type method modifiers";
    }

    Moose::Util::add_method_modifier($meta, $type, \@_);
}

sub before { _add_method_modifier('before', @_) }

sub after  { _add_method_modifier('after',  @_) }

sub around { _add_method_modifier('around', @_) }

# see Moose.pm for discussion
sub super {
    return unless $Moose::SUPER_BODY;
    $Moose::SUPER_BODY->(@Moose::SUPER_ARGS);
}

sub override {
    my $meta = shift;
    my ( $name, $code ) = @_;
    $meta->add_override_method_modifier( $name, $code );
}

sub inner {
    croak "Roles cannot support 'inner'";
}

sub augment {
    croak "Roles cannot support 'augment'";
}

Moose::Exporter->setup_import_methods(
    with_meta => [
        qw( with requires excludes has before after around override )
    ],
    as_is => [
        qw( extends super inner augment ),
        \&Carp::confess,
        \&Scalar::Util::blessed,
    ],
);

sub init_meta {
    shift;
    my %args = @_;

    my $role = $args{for_class};

    unless ($role) {
        require Moose;
        Moose->throw_error("Cannot call init_meta without specifying a for_class");
    }

    my $metaclass = $args{metaclass} || "Moose::Meta::Role";
    my $meta_name = exists $args{meta_name} ? $args{meta_name} : 'meta';

    Moose->throw_error("The Metaclass $metaclass must be loaded. (Perhaps you forgot to 'use $metaclass'?)")
        unless is_class_loaded($metaclass);

    Moose->throw_error("The Metaclass $metaclass must be a subclass of Moose::Meta::Role.")
        unless $metaclass->isa('Moose::Meta::Role');

    # make a subtype for each Moose role
    role_type $role unless find_type_constraint($role);

    my $meta;
    if ( $meta = Class::MOP::get_metaclass_by_name($role) ) {
        unless ( $meta->isa("Moose::Meta::Role") ) {
            my $error_message = "$role already has a metaclass, but it does not inherit $metaclass ($meta).";
            if ( $meta->isa('Moose::Meta::Class') ) {
                Moose->throw_error($error_message . ' You cannot make the same thing a role and a class. Remove either Moose or Moose::Role.');
            } else {
                Moose->throw_error($error_message);
            }
        }
    }
    else {
        $meta = $metaclass->initialize($role);
    }

    if (defined $meta_name) {
        # also check for inherited non moose 'meta' method?
        my $existing = $meta->get_method($meta_name);
        if ($existing && !$existing->isa('Class::MOP::Method::Meta')) {
            Carp::cluck "Moose::Role is overwriting an existing method named "
                      . "$meta_name in role $role with a method "
                      . "which returns the class's metaclass. If this is "
                      . "actually what you want, you should remove the "
                      . "existing method, otherwise, you should rename or "
                      . "disable this generated method using the "
                      . "'-meta_name' option to 'use Moose::Role'.";
        }
        $meta->_add_meta_method($meta_name);
    }

    return $meta;
}

1;

# ABSTRACT: The Moose Role

__END__

=pod

=head1 NAME

Moose::Role - The Moose Role

=head1 VERSION

version 2.1005

=head1 SYNOPSIS

  package Eq;
  use Moose::Role; # automatically turns on strict and warnings

  requires 'equal';

  sub no_equal {
      my ($self, $other) = @_;
      !$self->equal($other);
  }

  # ... then in your classes

  package Currency;
  use Moose; # automatically turns on strict and warnings

  with 'Eq';

  sub equal {
      my ($self, $other) = @_;
      $self->as_float == $other->as_float;
  }

  # ... and also

  package Comparator;
  use Moose;

  has compare_to => (
      is      => 'ro',
      does    => 'Eq',
      handles => 'Eq',
  );

  # ... which allows

  my $currency1 = Currency->new(...);
  my $currency2 = Currency->new(...);
  Comparator->new(compare_to => $currency1)->equal($currency2);

=head1 DESCRIPTION

The concept of roles is documented in L<Moose::Manual::Roles>. This document
serves as API documentation.

=head1 EXPORTED FUNCTIONS

Moose::Role currently supports all of the functions that L<Moose> exports, but
differs slightly in how some items are handled (see L</CAVEATS> below for
details).

Moose::Role also offers two role-specific keyword exports:

=over 4

=item B<requires (@method_names)>

Roles can require that certain methods are implemented by any class which
C<does> the role.

Note that attribute accessors also count as methods for the purposes
of satisfying the requirements of a role.

=item B<excludes (@role_names)>

Roles can C<exclude> other roles, in effect saying "I can never be combined
with these C<@role_names>". This is a feature which should not be used
lightly.

=back

=head2 B<unimport>

Moose::Role offers a way to remove the keywords it exports, through the
C<unimport> method. You simply have to say C<no Moose::Role> at the bottom of
your code for this to work.

=head1 METACLASS

When you use Moose::Role, you can specify traits which will be applied to your
role metaclass:

    use Moose::Role -traits => 'My::Trait';

This is very similar to the attribute traits feature. When you do
this, your class's C<meta> object will have the specified traits
applied to it. See L<Moose/Metaclass and Trait Name Resolution> for more
details.

=head1 APPLYING ROLES

In addition to being applied to a class using the 'with' syntax (see
L<Moose::Manual::Roles>) and using the L<Moose::Util> 'apply_all_roles'
method, roles may also be applied to an instance of a class using
L<Moose::Util> 'apply_all_roles' or the role's metaclass:

   MyApp::Test::SomeRole->meta->apply( $instance );

Doing this creates a new, mutable, anonymous subclass, applies the role to that,
and reblesses. In a debugger, for example, you will see class names of the
form C< Moose::Meta::Class::__ANON__::SERIAL::6 >, which means that doing a
'ref' on your instance may not return what you expect. See L<Moose::Object> for
'DOES'.

Additional params may be added to the new instance by providing
'rebless_params'. See L<Moose::Meta::Role::Application::ToInstance>.

=head1 CAVEATS

Role support has only a few caveats:

=over 4

=item *

Roles cannot use the C<extends> keyword; it will throw an exception for now.
The same is true of the C<augment> and C<inner> keywords (not sure those
really make sense for roles). All other Moose keywords will be I<deferred>
so that they can be applied to the consuming class.

=item *

Role composition does its best to B<not> be order-sensitive when it comes to
conflict resolution and requirements detection. However, it is order-sensitive
when it comes to method modifiers. All before/around/after modifiers are
included whenever a role is composed into a class, and then applied in the order
in which the roles are used. This also means that there is no conflict for
before/around/after modifiers.

In most cases, this will be a non-issue; however, it is something to keep in
mind when using method modifiers in a role. You should never assume any
ordering.

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
