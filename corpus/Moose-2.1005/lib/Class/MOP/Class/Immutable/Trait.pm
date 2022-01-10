package Class::MOP::Class::Immutable::Trait;
BEGIN {
  $Class::MOP::Class::Immutable::Trait::AUTHORITY = 'cpan:STEVAN';
}
{
  $Class::MOP::Class::Immutable::Trait::VERSION = '2.1005';
}

use strict;
use warnings;

use MRO::Compat;

use Carp 'confess';
use Scalar::Util 'blessed', 'weaken';

# the original class of the metaclass instance
sub _get_mutable_metaclass_name { $_[0]{__immutable}{original_class} }

sub is_mutable   { 0 }
sub is_immutable { 1 }

sub _immutable_metaclass { ref $_[1] }

sub _immutable_read_only {
    my $name = shift;
    confess "The '$name' method is read-only when called on an immutable instance";
}

sub _immutable_cannot_call {
    my $name = shift;
    Carp::confess "The '$name' method cannot be called on an immutable instance";
}

for my $name (qw/superclasses/) {
    no strict 'refs';
    *{__PACKAGE__."::$name"} = sub {
        my $orig = shift;
        my $self = shift;
        _immutable_read_only($name) if @_;
        $self->$orig;
    };
}

for my $name (qw/add_method alias_method remove_method add_attribute remove_attribute remove_package_symbol add_package_symbol/) {
    no strict 'refs';
    *{__PACKAGE__."::$name"} = sub { _immutable_cannot_call($name) };
}

sub class_precedence_list {
    my $orig = shift;
    my $self = shift;
    @{ $self->{__immutable}{class_precedence_list}
            ||= [ $self->$orig ] };
}

sub linearized_isa {
    my $orig = shift;
    my $self = shift;
    @{ $self->{__immutable}{linearized_isa} ||= [ $self->$orig ] };
}

sub get_all_methods {
    my $orig = shift;
    my $self = shift;
    @{ $self->{__immutable}{get_all_methods} ||= [ $self->$orig ] };
}

sub get_all_method_names {
    my $orig = shift;
    my $self = shift;
    @{ $self->{__immutable}{get_all_method_names} ||= [ $self->$orig ] };
}

sub get_all_attributes {
    my $orig = shift;
    my $self = shift;
    @{ $self->{__immutable}{get_all_attributes} ||= [ $self->$orig ] };
}

sub get_meta_instance {
    my $orig = shift;
    my $self = shift;
    $self->{__immutable}{get_meta_instance} ||= $self->$orig;
}

sub _method_map {
    my $orig = shift;
    my $self = shift;
    $self->{__immutable}{_method_map} ||= $self->$orig;
}

1;

# ABSTRACT: Implements immutability for metaclass objects

__END__

=pod

=head1 NAME

Class::MOP::Class::Immutable::Trait - Implements immutability for metaclass objects

=head1 VERSION

version 2.1005

=head1 DESCRIPTION

This class provides a pseudo-trait that is applied to immutable metaclass
objects. In reality, it is simply a parent class.

It implements caching and read-only-ness for various metaclass methods.

=head1 AUTHOR

Moose is maintained by the Moose Cabal, along with the help of many contributors. See L<Moose/CABAL> and L<Moose/CONTRIBUTORS> for details.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Infinity Interactive, Inc..

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
