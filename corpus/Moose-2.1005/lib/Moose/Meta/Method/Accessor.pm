
package Moose::Meta::Method::Accessor;
BEGIN {
  $Moose::Meta::Method::Accessor::AUTHORITY = 'cpan:STEVAN';
}
{
  $Moose::Meta::Method::Accessor::VERSION = '2.1005';
}

use strict;
use warnings;

use Try::Tiny;

use base 'Moose::Meta::Method',
         'Class::MOP::Method::Accessor';

# multiple inheritance is terrible
sub new {
    goto &Class::MOP::Method::Accessor::new;
}

sub _new {
    goto &Class::MOP::Method::Accessor::_new;
}

sub _error_thrower {
    my $self = shift;
    return $self->associated_attribute
        if ref($self) && defined($self->associated_attribute);
    return $self->SUPER::_error_thrower;
}

sub _compile_code {
    my $self = shift;
    my @args = @_;
    try {
        $self->SUPER::_compile_code(@args);
    }
    catch {
        $self->throw_error(
            'Could not create writer for '
          . "'" . $self->associated_attribute->name . "' "
          . 'because ' . $_,
            error => $_,
        );
    };
}

sub _eval_environment {
    my $self = shift;
    return $self->associated_attribute->_eval_environment;
}

sub _instance_is_inlinable {
    my $self = shift;
    return $self->associated_attribute->associated_class->instance_metaclass->is_inlinable;
}

sub _generate_reader_method {
    my $self = shift;
    $self->_instance_is_inlinable ? $self->_generate_reader_method_inline(@_)
                                  : $self->SUPER::_generate_reader_method(@_);
}

sub _generate_writer_method {
    my $self = shift;
    $self->_instance_is_inlinable ? $self->_generate_writer_method_inline(@_)
                                  : $self->SUPER::_generate_writer_method(@_);
}

sub _generate_accessor_method {
    my $self = shift;
    $self->_instance_is_inlinable ? $self->_generate_accessor_method_inline(@_)
                                  : $self->SUPER::_generate_accessor_method(@_);
}

sub _generate_predicate_method {
    my $self = shift;
    $self->_instance_is_inlinable ? $self->_generate_predicate_method_inline(@_)
                                  : $self->SUPER::_generate_predicate_method(@_);
}

sub _generate_clearer_method {
    my $self = shift;
    $self->_instance_is_inlinable ? $self->_generate_clearer_method_inline(@_)
                                  : $self->SUPER::_generate_clearer_method(@_);
}

sub _writer_value_needs_copy {
    shift->associated_attribute->_writer_value_needs_copy(@_);
}

sub _inline_tc_code {
    shift->associated_attribute->_inline_tc_code(@_);
}

sub _inline_check_coercion {
    shift->associated_attribute->_inline_check_coercion(@_);
}

sub _inline_check_constraint {
    shift->associated_attribute->_inline_check_constraint(@_);
}

sub _inline_check_lazy {
    shift->associated_attribute->_inline_check_lazy(@_);
}

sub _inline_store_value {
    shift->associated_attribute->_inline_instance_set(@_) . ';';
}

sub _inline_get_old_value_for_trigger {
    shift->associated_attribute->_inline_get_old_value_for_trigger(@_);
}

sub _inline_trigger {
    shift->associated_attribute->_inline_trigger(@_);
}

sub _get_value {
    shift->associated_attribute->_inline_instance_get(@_);
}

sub _has_value {
    shift->associated_attribute->_inline_instance_has(@_);
}

1;

# ABSTRACT: A Moose Method metaclass for accessors

__END__

=pod

=head1 NAME

Moose::Meta::Method::Accessor - A Moose Method metaclass for accessors

=head1 VERSION

version 2.1005

=head1 DESCRIPTION

This class is a subclass of L<Class::MOP::Method::Accessor> that
provides additional Moose-specific functionality, all of which is
private.

To understand this class, you should read the the
L<Class::MOP::Method::Accessor> documentation.

=head1 BUGS

See L<Moose/BUGS> for details on reporting bugs.

=head1 AUTHOR

Moose is maintained by the Moose Cabal, along with the help of many contributors. See L<Moose/CABAL> and L<Moose/CONTRIBUTORS> for details.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Infinity Interactive, Inc..

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
