package Moose::Meta::TypeConstraint::Class;
BEGIN {
  $Moose::Meta::TypeConstraint::Class::AUTHORITY = 'cpan:STEVAN';
}
{
  $Moose::Meta::TypeConstraint::Class::VERSION = '2.1005';
}

use strict;
use warnings;
use metaclass;

use B;
use Scalar::Util 'blessed';
use Moose::Util::TypeConstraints ();

use base 'Moose::Meta::TypeConstraint';

__PACKAGE__->meta->add_attribute('class' => (
    reader => 'class',
    Class::MOP::_definition_context(),
));

my $inliner = sub {
    my $self = shift;
    my $val  = shift;

    return 'Scalar::Util::blessed(' . $val . ')'
             . ' && ' . $val . '->isa(' . B::perlstring($self->class) . ')';
};

sub new {
    my ( $class, %args ) = @_;

    $args{parent}
        = Moose::Util::TypeConstraints::find_type_constraint('Object');

    my $class_name = $args{class};
    $args{constraint} = sub { $_[0]->isa($class_name) };

    $args{inlined} = $inliner;

    my $self = $class->SUPER::new( \%args );

    $self->compile_type_constraint();

    return $self;
}

sub parents {
    my $self = shift;
    return (
        $self->parent,
        map {
            # FIXME find_type_constraint might find a TC named after the class but that isn't really it
            # I did this anyway since it's a convention that preceded TypeConstraint::Class, and it should DWIM
            # if anybody thinks this problematic please discuss on IRC.
            # a possible fix is to add by attr indexing to the type registry to find types of a certain property
            # regardless of their name
            Moose::Util::TypeConstraints::find_type_constraint($_)
                ||
            __PACKAGE__->new( class => $_, name => "__ANON__" )
        } Class::MOP::class_of($self->class)->superclasses,
    );
}

sub equals {
    my ( $self, $type_or_name ) = @_;

    my $other = Moose::Util::TypeConstraints::find_type_constraint($type_or_name);

    if (!defined($other)) {
        if (!ref($type_or_name)) {
            return $self->class eq $type_or_name;
        }
        return;
    }

    return unless $other->isa(__PACKAGE__);

    return $self->class eq $other->class;
}

sub is_a_type_of {
    my ($self, $type_or_name) = @_;

    ($self->equals($type_or_name) || $self->is_subtype_of($type_or_name));
}

sub is_subtype_of {
    my ($self, $type_or_name_or_class ) = @_;

    my $type = Moose::Util::TypeConstraints::find_type_constraint($type_or_name_or_class);

    if ( not defined $type ) {
        if ( not ref $type_or_name_or_class ) {
            # it might be a class
            my $class = $self->class;
            return 1 if $class ne $type_or_name_or_class
                     && $class->isa( $type_or_name_or_class );
        }
        return;
    }

    if ( $type->isa(__PACKAGE__) && $type->class ne $self->class) {
        # if $type_or_name_or_class isn't a class, it might be the TC name of another ::Class type
        # or it could also just be a type object in this branch
        return $self->class->isa( $type->class );
    } else {
        # the only other thing we are a subtype of is Object
        $self->SUPER::is_subtype_of($type);
    }
}

# This is a bit counter-intuitive, but a child type of a Class type
# constraint is not itself a Class type constraint (it has no class
# attribute). This whole create_child_type thing needs some changing
# though, probably making MMC->new a factory or something.
sub create_child_type {
    my ($self, @args) = @_;
    return Moose::Meta::TypeConstraint->new(@args, parent => $self);
}

sub get_message {
    my $self = shift;
    my ($value) = @_;

    if ($self->has_message) {
        return $self->SUPER::get_message(@_);
    }

    $value = (defined $value ? overload::StrVal($value) : 'undef');
    return "Validation failed for '" . $self->name . "' with value $value (not isa " . $self->class . ")";
}

1;

# ABSTRACT: Class/TypeConstraint parallel hierarchy

__END__

=pod

=head1 NAME

Moose::Meta::TypeConstraint::Class - Class/TypeConstraint parallel hierarchy

=head1 VERSION

version 2.1005

=head1 DESCRIPTION

This class represents type constraints for a class.

=head1 INHERITANCE

C<Moose::Meta::TypeConstraint::Class> is a subclass of
L<Moose::Meta::TypeConstraint>.

=head1 METHODS

=over 4

=item B<< Moose::Meta::TypeConstraint::Class->new(%options) >>

This creates a new class type constraint based on the given
C<%options>.

It takes the same options as its parent, with two exceptions. First,
it requires an additional option, C<class>, which is name of the
constraint's class.  Second, it automatically sets the parent to the
C<Object> type.

The constructor also overrides the hand optimized type constraint with
one it creates internally.

=item B<< $constraint->class >>

Returns the class name associated with the constraint.

=item B<< $constraint->parents >>

Returns all the type's parent types, corresponding to its parent
classes.

=item B<< $constraint->is_subtype_of($type_name_or_object) >>

If the given type is also a class type, then this checks that the
type's class is a subclass of the other type's class.

Otherwise it falls back to the implementation in
L<Moose::Meta::TypeConstraint>.

=item B<< $constraint->create_child_type(%options) >>

This returns a new L<Moose::Meta::TypeConstraint> object with the type
as its parent.

Note that it does I<not> return a
C<Moose::Meta::TypeConstraint::Class> object!

=item B<< $constraint->get_message($value) >>

This is the same as L<Moose::Meta::TypeConstraint/get_message> except
that it explicitly says C<isa> was checked. This is to help users deal
with accidentally autovivified type constraints.

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
