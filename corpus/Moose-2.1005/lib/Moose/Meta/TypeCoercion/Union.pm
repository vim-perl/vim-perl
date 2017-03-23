
package Moose::Meta::TypeCoercion::Union;
BEGIN {
  $Moose::Meta::TypeCoercion::Union::AUTHORITY = 'cpan:STEVAN';
}
{
  $Moose::Meta::TypeCoercion::Union::VERSION = '2.1005';
}

use strict;
use warnings;
use metaclass;

use Scalar::Util 'blessed';

use base 'Moose::Meta::TypeCoercion';

sub compile_type_coercion {
    my $self            = shift;
    my $type_constraint = $self->type_constraint;

    (blessed $type_constraint && $type_constraint->isa('Moose::Meta::TypeConstraint::Union'))
     || Moose->throw_error("You can only create a Moose::Meta::TypeCoercion::Union for a " .
                "Moose::Meta::TypeConstraint::Union, not a $type_constraint");

    $self->_compiled_type_coercion(
        sub {
            my $value = shift;

            foreach my $type ( grep { $_->has_coercion }
                @{ $type_constraint->type_constraints } ) {
                my $temp = $type->coerce($value);
                return $temp if $type_constraint->check($temp);
            }

            return $value;
        }
    );
}

sub has_coercion_for_type { 0 }

sub add_type_coercions {
    require Moose;
    Moose->throw_error("Cannot add additional type coercions to Union types");
}

1;

# ABSTRACT: The Moose Type Coercion metaclass for Unions

__END__

=pod

=head1 NAME

Moose::Meta::TypeCoercion::Union - The Moose Type Coercion metaclass for Unions

=head1 VERSION

version 2.1005

=head1 DESCRIPTION

This is a subclass of L<Moose::Meta::TypeCoercion> that is used for
L<Moose::Meta::TypeConstraint::Union> objects.
=head1 METHODS

=over 4

=item B<< $coercion->has_coercion_for_type >>

This method always returns false.

=item B<< $coercion->add_type_coercions >>

This method always throws an error. You cannot add coercions to a
union type coercion.

=item B<< $coercion->coerce($value) >>

This method will coerce by trying the coercions for each type in the
union.

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
