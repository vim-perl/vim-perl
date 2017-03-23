package Moose::Util;
BEGIN {
  $Moose::Util::AUTHORITY = 'cpan:STEVAN';
}
{
  $Moose::Util::VERSION = '2.1005';
}

use strict;
use warnings;

use Class::Load 0.07 qw(load_class load_first_existing_class);
use Data::OptList;
use Params::Util qw( _STRING );
use Sub::Exporter;
use Scalar::Util 'blessed';
use List::Util qw(first);
use List::MoreUtils qw(any all);
use overload ();
use Try::Tiny;
use Class::MOP;

my @exports = qw[
    find_meta
    does_role
    search_class_by_role
    ensure_all_roles
    apply_all_roles
    with_traits
    get_all_init_args
    get_all_attribute_values
    resolve_metatrait_alias
    resolve_metaclass_alias
    add_method_modifier
    english_list
    meta_attribute_alias
    meta_class_alias
];

Sub::Exporter::setup_exporter({
    exports => \@exports,
    groups  => { all => \@exports }
});

## some utils for the utils ...

sub find_meta { Class::MOP::class_of(@_) }

## the functions ...

sub does_role {
    my ($class_or_obj, $role) = @_;

    if (try { $class_or_obj->isa('Moose::Object') }) {
        return $class_or_obj->does($role);
    }

    my $meta = find_meta($class_or_obj);

    return unless defined $meta;
    return unless $meta->can('does_role');
    return 1 if $meta->does_role($role);
    return;
}

sub search_class_by_role {
    my ($class_or_obj, $role) = @_;

    my $meta = find_meta($class_or_obj);

    return unless defined $meta;

    my $role_name = blessed $role ? $role->name : $role;

    foreach my $class ($meta->class_precedence_list) {

        my $_meta = find_meta($class);

        next unless defined $_meta;

        foreach my $role (@{ $_meta->roles || [] }) {
            return $class if $role->name eq $role_name;
        }
    }

    return;
}

# this can possibly behave in unexpected ways because the roles being composed
# before being applied could differ from call to call; I'm not sure if or how
# to document this possible quirk.
sub ensure_all_roles {
    my $applicant = shift;
    _apply_all_roles($applicant, sub { !does_role($applicant, $_) }, @_);
}

sub apply_all_roles {
    my $applicant = shift;
    _apply_all_roles($applicant, undef, @_);
}

sub _apply_all_roles {
    my $applicant = shift;
    my $role_filter = shift;

    unless (@_) {
        require Moose;
        Moose->throw_error("Must specify at least one role to apply to $applicant");
    }

    # If @_ contains role meta objects, mkopt will think that they're values,
    # because they're references.  In other words (roleobj1, roleobj2,
    # roleobj3) will become [ [ roleobj1, roleobj2 ], [ roleobj3, undef ] ]
    # -- this is no good.  We'll preprocess @_ first to eliminate the potential
    # bug.
    # -- rjbs, 2011-04-08
    my $roles = Data::OptList::mkopt( [@_], {
      moniker   => 'role',
      name_test => sub {
        ! ref $_[0] or blessed($_[0]) && $_[0]->isa('Moose::Meta::Role')
      }
    });

    my @role_metas;
    foreach my $role (@$roles) {
        my $meta;

        if ( blessed $role->[0] ) {
            $meta = $role->[0];
        }
        else {
            load_class( $role->[0] , $role->[1] );
            $meta = find_meta( $role->[0] );
        }

        unless ($meta && $meta->isa('Moose::Meta::Role') ) {
            require Moose;
            Moose->throw_error( "You can only consume roles, "
                    . $role->[0]
                    . " is not a Moose role" );
        }

        push @role_metas, [ $meta, $role->[1] ];
    }

    if ( defined $role_filter ) {
        @role_metas = grep { local $_ = $_->[0]; $role_filter->() } @role_metas;
    }

    return unless @role_metas;

    load_class($applicant)
        unless blessed($applicant)
            || Class::MOP::class_of($applicant);

    my $meta = ( blessed $applicant ? $applicant : Moose::Meta::Class->initialize($applicant) );

    if ( scalar @role_metas == 1 ) {
        my ( $role, $params ) = @{ $role_metas[0] };
        $role->apply( $meta, ( defined $params ? %$params : () ) );
    }
    else {
        Moose::Meta::Role->combine(@role_metas)->apply($meta);
    }
}

sub with_traits {
    my ($class, @roles) = @_;
    return $class unless @roles;
    return Moose::Meta::Class->create_anon_class(
        superclasses => [$class],
        roles        => \@roles,
        cache        => 1,
    )->name;
}

# instance deconstruction ...

sub get_all_attribute_values {
    my ($class, $instance) = @_;
    return +{
        map { $_->name => $_->get_value($instance) }
            grep { $_->has_value($instance) }
                $class->get_all_attributes
    };
}

sub get_all_init_args {
    my ($class, $instance) = @_;
    return +{
        map { $_->init_arg => $_->get_value($instance) }
            grep { $_->has_value($instance) }
                grep { defined($_->init_arg) }
                    $class->get_all_attributes
    };
}

sub resolve_metatrait_alias {
    return resolve_metaclass_alias( @_, trait => 1 );
}

sub _build_alias_package_name {
    my ($type, $name, $trait) = @_;
    return 'Moose::Meta::'
         . $type
         . '::Custom::'
         . ( $trait ? 'Trait::' : '' )
         . $name;
}

{
    my %cache;

    sub resolve_metaclass_alias {
        my ( $type, $metaclass_name, %options ) = @_;

        my $cache_key = $type . q{ } . ( $options{trait} ? '-Trait' : '' );
        return $cache{$cache_key}{$metaclass_name}
            if $cache{$cache_key}{$metaclass_name};

        my $possible_full_name = _build_alias_package_name(
            $type, $metaclass_name, $options{trait}
        );

        my $loaded_class = load_first_existing_class(
            $possible_full_name,
            $metaclass_name
        );

        return $cache{$cache_key}{$metaclass_name}
            = $loaded_class->can('register_implementation')
            ? $loaded_class->register_implementation
            : $loaded_class;
    }
}

sub add_method_modifier {
    my ( $class_or_obj, $modifier_name, $args ) = @_;
    my $meta
        = $class_or_obj->can('add_before_method_modifier')
        ? $class_or_obj
        : find_meta($class_or_obj);
    my $code                = pop @{$args};
    my $add_modifier_method = 'add_' . $modifier_name . '_method_modifier';
    if ( my $method_modifier_type = ref( @{$args}[0] ) ) {
        if ( $method_modifier_type eq 'Regexp' ) {
            my @all_methods = $meta->get_all_methods;
            my @matched_methods
                = grep { $_->name =~ @{$args}[0] } @all_methods;
            $meta->$add_modifier_method( $_->name, $code )
                for @matched_methods;
        }
        elsif ($method_modifier_type eq 'ARRAY') {
            $meta->$add_modifier_method( $_, $code ) for @{$args->[0]};
        }
        else {
            $meta->throw_error(
                sprintf(
                    "Methods passed to %s must be provided as a list, arrayref or regex, not %s",
                    $modifier_name,
                    $method_modifier_type,
                )
            );
        }
    }
    else {
        $meta->$add_modifier_method( $_, $code ) for @{$args};
    }
}

sub english_list {
    my @items = sort @_;

    return $items[0] if @items == 1;
    return "$items[0] and $items[1]" if @items == 2;

    my $tail = pop @items;
    my $list = join ', ', @items;
    $list .= ', and ' . $tail;

    return $list;
}

sub _caller_info {
    my $level = @_ ? ($_[0] + 1) : 2;
    my %info;
    @info{qw(package file line)} = caller($level);
    return %info;
}

sub _create_alias {
    my ($type, $name, $trait, $for) = @_;
    my $package = _build_alias_package_name($type, $name, $trait);
    Class::MOP::Class->initialize($package)->add_method(
        register_implementation => sub { $for }
    );
}

sub meta_attribute_alias {
    my ($to, $from) = @_;
    $from ||= caller;
    my $meta = Class::MOP::class_of($from);
    my $trait = $meta->isa('Moose::Meta::Role');
    _create_alias('Attribute', $to, $trait, $from);
}

sub meta_class_alias {
    my ($to, $from) = @_;
    $from ||= caller;
    my $meta = Class::MOP::class_of($from);
    my $trait = $meta->isa('Moose::Meta::Role');
    _create_alias('Class', $to, $trait, $from);
}

# XXX - this should be added to Params::Util
sub _STRINGLIKE0 ($) {
    return 1 if _STRING( $_[0] );
    if ( blessed $_[0] ) {
        return overload::Method( $_[0], q{""} );
    }

    return 1 if defined $_[0] && $_[0] eq q{};

    return 0;
}

sub _reconcile_roles_for_metaclass {
    my ($class_meta_name, $super_meta_name) = @_;

    my @role_differences = _role_differences(
        $class_meta_name, $super_meta_name,
    );

    # handle the case where we need to fix compatibility between a class and
    # its parent, but all roles in the class are already also done by the
    # parent
    # see t/metaclasses/metaclass_compat_no_fixing_bug.t
    return $super_meta_name
        unless @role_differences;

    return Moose::Meta::Class->create_anon_class(
        superclasses => [$super_meta_name],
        roles        => [map { $_->name } @role_differences],
        cache        => 1,
    )->name;
}

sub _role_differences {
    my ($class_meta_name, $super_meta_name) = @_;
    my @super_role_metas = map {
        $_->isa('Moose::Meta::Role::Composite')
            ? (@{ $_->get_roles })
            : ($_)
    } $super_meta_name->meta->can('_roles_with_inheritance')
        ? $super_meta_name->meta->_roles_with_inheritance
    : $super_meta_name->meta->can('roles')
        ? @{ $super_meta_name->meta->roles }
    :     ();
    my @role_metas = map {
        $_->isa('Moose::Meta::Role::Composite')
            ? (@{ $_->get_roles })
            : ($_)
    } $class_meta_name->meta->can('_roles_with_inheritance')
        ? $class_meta_name->meta->_roles_with_inheritance
    : $class_meta_name->meta->can('roles')
        ? @{ $class_meta_name->meta->roles }
    :     ();
    my @differences;
    for my $role_meta (@role_metas) {
        push @differences, $role_meta
            unless any { $_->name eq $role_meta->name } @super_role_metas;
    }
    return @differences;
}

sub _classes_differ_by_roles_only {
    my ( $self_meta_name, $super_meta_name ) = @_;

    my $common_base_name
        = _find_common_base( $self_meta_name, $super_meta_name );

    return unless defined $common_base_name;

    my @super_meta_name_ancestor_names
        = _get_ancestors_until( $super_meta_name, $common_base_name );
    my @class_meta_name_ancestor_names
        = _get_ancestors_until( $self_meta_name, $common_base_name );

    return
        unless all { _is_role_only_subclass($_) }
        @super_meta_name_ancestor_names,
        @class_meta_name_ancestor_names;

    return 1;
}

sub _find_common_base {
    my ($meta1, $meta2) = map { Class::MOP::class_of($_) } @_;
    return unless defined $meta1 && defined $meta2;

    # FIXME? This doesn't account for multiple inheritance (not sure
    # if it needs to though). For example, if somewhere in $meta1's
    # history it inherits from both ClassA and ClassB, and $meta2
    # inherits from ClassB & ClassA, does it matter? And what crazy
    # fool would do that anyway?

    my %meta1_parents = map { $_ => 1 } $meta1->linearized_isa;

    return first { $meta1_parents{$_} } $meta2->linearized_isa;
}

sub _get_ancestors_until {
    my ($start_name, $until_name) = @_;

    my @ancestor_names;
    for my $ancestor_name (Class::MOP::class_of($start_name)->linearized_isa) {
        last if $ancestor_name eq $until_name;
        push @ancestor_names, $ancestor_name;
    }
    return @ancestor_names;
}

sub _is_role_only_subclass {
    my ($meta_name) = @_;
    my $meta = Class::MOP::Class->initialize($meta_name);
    my @parent_names = $meta->superclasses;

    # XXX: don't feel like messing with multiple inheritance here... what would
    # that even do?
    return unless @parent_names == 1;
    my ($parent_name) = @parent_names;
    my $parent_meta = Class::MOP::Class->initialize($parent_name);

    # only get the roles attached to this particular class, don't look at
    # superclasses
    my @roles = $meta->can('calculate_all_roles')
                    ? $meta->calculate_all_roles
                    : ();

    # it's obviously not a role-only subclass if it doesn't do any roles
    return unless @roles;

    # loop over all methods that are a part of the current class
    # (not inherited)
    for my $method ( $meta->_get_local_methods ) {
        # always ignore meta
        next if $method->isa('Class::MOP::Method::Meta');
        # we'll deal with attributes below
        next if $method->can('associated_attribute');
        # if the method comes from a role we consumed, ignore it
        next if $meta->can('does_role')
             && $meta->does_role($method->original_package_name);
        # FIXME - this really isn't right. Just because a modifier is
        # defined in a role doesn't mean it isn't _also_ defined in the
        # subclass.
        next if $method->isa('Class::MOP::Method::Wrapped')
             && (
                 (!scalar($method->around_modifiers)
               || any { $_->has_around_method_modifiers($method->name) } @roles)
              && (!scalar($method->before_modifiers)
               || any { $_->has_before_method_modifiers($method->name) } @roles)
              && (!scalar($method->after_modifiers)
               || any { $_->has_after_method_modifiers($method->name) } @roles)
                );

        return 0;
    }

    # loop over all attributes that are a part of the current class
    # (not inherited)
    # FIXME - this really isn't right. Just because an attribute is
    # defined in a role doesn't mean it isn't _also_ defined in the
    # subclass.
    for my $attr (map { $meta->get_attribute($_) } $meta->get_attribute_list) {
        next if any { $_->has_attribute($attr->name) } @roles;

        return 0;
    }

    return 1;
}

1;

# ABSTRACT: Utilities for working with Moose classes

__END__

=pod

=head1 NAME

Moose::Util - Utilities for working with Moose classes

=head1 VERSION

version 2.1005

=head1 SYNOPSIS

  use Moose::Util qw/find_meta does_role search_class_by_role/;

  my $meta = find_meta($object) || die "No metaclass found";

  if (does_role($object, $role)) {
    print "The object can do $role!\n";
  }

  my $class = search_class_by_role($object, 'FooRole');
  print "Nearest class with 'FooRole' is $class\n";

=head1 DESCRIPTION

This module provides a set of utility functions. Many of these
functions are intended for use in Moose itself or MooseX modules, but
some of them may be useful for use in your own code.

=head1 EXPORTED FUNCTIONS

=over 4

=item B<find_meta($class_or_obj)>

This method takes a class name or object and attempts to find a
metaclass for the class, if one exists. It will B<not> create one if it
does not yet exist.

=item B<does_role($class_or_obj, $role_or_obj)>

Returns true if C<$class_or_obj> does the given C<$role_or_obj>. The role can
be provided as a name or a L<Moose::Meta::Role> object.

The class must already have a metaclass for this to work. If it doesn't, this
function simply returns false.

=item B<search_class_by_role($class_or_obj, $role_or_obj)>

Returns the first class in the class's precedence list that does
C<$role_or_obj>, if any. The role can be either a name or a
L<Moose::Meta::Role> object.

The class must already have a metaclass for this to work.

=item B<apply_all_roles($applicant, @roles)>

This function applies one or more roles to the given C<$applicant> The
applicant can be a role name, class name, or object.

The C<$applicant> must already have a metaclass object.

The list of C<@roles> should a list of names or L<Moose::Meta::Role> objects,
each of which can be followed by an optional hash reference of options
(C<-excludes> and C<-alias>).

=item B<ensure_all_roles($applicant, @roles)>

This function is similar to C<apply_all_roles>, but only applies roles that
C<$applicant> does not already consume.

=item B<with_traits($class_name, @role_names)>

This function creates a new class from C<$class_name> with each of
C<@role_names> applied. It returns the name of the new class.

=item B<get_all_attribute_values($meta, $instance)>

Returns a hash reference containing all of the C<$instance>'s
attributes. The keys are attribute names.

=item B<get_all_init_args($meta, $instance)>

Returns a hash reference containing all of the C<init_arg> values for
the instance's attributes. The values are the associated attribute
values. If an attribute does not have a defined C<init_arg>, it is
skipped.

This could be useful in cloning an object.

=item B<resolve_metaclass_alias($category, $name, %options)>

=item B<resolve_metatrait_alias($category, $name, %options)>

Resolves a short name to a full class name. Short names are often used
when specifying the C<metaclass> or C<traits> option for an attribute:

    has foo => (
        metaclass => "Bar",
    );

The name resolution mechanism is covered in
L<Moose/Metaclass and Trait Name Resolution>.

=item B<meta_class_alias($to[, $from])>

=item B<meta_attribute_alias($to[, $from])>

Create an alias from the class C<$from> (or the current package, if
C<$from> is unspecified), so that
L<Moose/Metaclass and Trait Name Resolution> works properly.

=item B<english_list(@items)>

Given a list of scalars, turns them into a proper list in English
("one and two", "one, two, three, and four"). This is used to help us
make nicer error messages.

=back

=head1 TODO

Here is a list of possible functions to write

=over 4

=item discovering original method from modified method

=item search for origin class of a method or attribute

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
