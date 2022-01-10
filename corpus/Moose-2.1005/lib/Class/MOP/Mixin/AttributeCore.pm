package Class::MOP::Mixin::AttributeCore;
BEGIN {
  $Class::MOP::Mixin::AttributeCore::AUTHORITY = 'cpan:STEVAN';
}
{
  $Class::MOP::Mixin::AttributeCore::VERSION = '2.1005';
}

use strict;
use warnings;

use Scalar::Util 'blessed';

use base 'Class::MOP::Mixin';

sub has_accessor        { defined $_[0]->{'accessor'} }
sub has_reader          { defined $_[0]->{'reader'} }
sub has_writer          { defined $_[0]->{'writer'} }
sub has_predicate       { defined $_[0]->{'predicate'} }
sub has_clearer         { defined $_[0]->{'clearer'} }
sub has_builder         { defined $_[0]->{'builder'} }
sub has_init_arg        { defined $_[0]->{'init_arg'} }
sub has_default         { exists  $_[0]->{'default'} }
sub has_initializer     { defined $_[0]->{'initializer'} }
sub has_insertion_order { defined $_[0]->{'insertion_order'} }

sub _set_insertion_order { $_[0]->{'insertion_order'} = $_[1] }

sub has_read_method  { $_[0]->has_reader || $_[0]->has_accessor }
sub has_write_method { $_[0]->has_writer || $_[0]->has_accessor }

sub is_default_a_coderef {
    # Uber hack because it is called from CMOP::Attribute constructor as
    # $class->is_default_a_coderef(\%options)
    my ($value) = ref $_[0] ? $_[0]->{'default'} : $_[1]->{'default'};

    return unless ref($value);

    return ref($value) eq 'CODE'
        || ( blessed($value) && $value->isa('Class::MOP::Method') );
}

sub default {
    my ( $self, $instance ) = @_;
    if ( defined $instance && $self->is_default_a_coderef ) {
        # if the default is a CODE ref, then we pass in the instance and
        # default can return a value based on that instance. Somewhat crude,
        # but works.
        return $self->{'default'}->($instance);
    }
    $self->{'default'};
}

1;

# ABSTRACT: Core attributes shared by attribute metaclasses

__END__

=pod

=head1 NAME

Class::MOP::Mixin::AttributeCore - Core attributes shared by attribute metaclasses

=head1 VERSION

version 2.1005

=head1 DESCRIPTION

This class implements the core attributes (aka properties) shared by all
attributes. See the L<Class::MOP::Attribute> documentation for API details.

=head1 AUTHOR

Moose is maintained by the Moose Cabal, along with the help of many contributors. See L<Moose/CABAL> and L<Moose/CONTRIBUTORS> for details.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Infinity Interactive, Inc..

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
