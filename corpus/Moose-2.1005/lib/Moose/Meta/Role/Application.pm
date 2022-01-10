package Moose::Meta::Role::Application;
BEGIN {
  $Moose::Meta::Role::Application::AUTHORITY = 'cpan:STEVAN';
}
{
  $Moose::Meta::Role::Application::VERSION = '2.1005';
}

use strict;
use warnings;
use metaclass;

__PACKAGE__->meta->add_attribute('method_exclusions' => (
    init_arg => '-excludes',
    reader   => 'get_method_exclusions',
    default  => sub { [] },
    Class::MOP::_definition_context(),
));

__PACKAGE__->meta->add_attribute('method_aliases' => (
    init_arg => '-alias',
    reader   => 'get_method_aliases',
    default  => sub { {} },
    Class::MOP::_definition_context(),
));

sub new {
    my ($class, %params) = @_;
    $class->_new(\%params);
}

sub is_method_excluded {
    my ($self, $method_name) = @_;
    foreach (@{$self->get_method_exclusions}) {
        return 1 if $_ eq $method_name;
    }
    return 0;
}

sub is_method_aliased {
    my ($self, $method_name) = @_;
    exists $self->get_method_aliases->{$method_name} ? 1 : 0
}

sub is_aliased_method {
    my ($self, $method_name) = @_;
    my %aliased_names = reverse %{$self->get_method_aliases};
    exists $aliased_names{$method_name} ? 1 : 0;
}

sub apply {
    my $self = shift;

    $self->check_role_exclusions(@_);
    $self->check_required_methods(@_);
    $self->check_required_attributes(@_);

    $self->apply_attributes(@_);
    $self->apply_methods(@_);

    $self->apply_override_method_modifiers(@_);

    $self->apply_before_method_modifiers(@_);
    $self->apply_around_method_modifiers(@_);
    $self->apply_after_method_modifiers(@_);
}

sub check_role_exclusions           { Carp::croak "Abstract Method" }
sub check_required_methods          { Carp::croak "Abstract Method" }
sub check_required_attributes       { Carp::croak "Abstract Method" }

sub apply_attributes                { Carp::croak "Abstract Method" }
sub apply_methods                   { Carp::croak "Abstract Method" }
sub apply_override_method_modifiers { Carp::croak "Abstract Method" }
sub apply_method_modifiers          { Carp::croak "Abstract Method" }

sub apply_before_method_modifiers   { (shift)->apply_method_modifiers('before' => @_) }
sub apply_around_method_modifiers   { (shift)->apply_method_modifiers('around' => @_) }
sub apply_after_method_modifiers    { (shift)->apply_method_modifiers('after'  => @_) }

1;

# ABSTRACT: A base class for role application

__END__

=pod

=head1 NAME

Moose::Meta::Role::Application - A base class for role application

=head1 VERSION

version 2.1005

=head1 DESCRIPTION

This is the abstract base class for role applications.

The API for this class and its subclasses still needs some
consideration, and is intentionally not yet documented.

=head2 METHODS

=over 4

=item B<new>

=item B<meta>

=item B<get_method_exclusions>

=item B<is_method_excluded>

=item B<get_method_aliases>

=item B<is_aliased_method>

=item B<is_method_aliased>

=item B<apply>

=item B<check_role_exclusions>

=item B<check_required_methods>

=item B<check_required_attributes>

=item B<apply_attributes>

=item B<apply_methods>

=item B<apply_method_modifiers>

=item B<apply_before_method_modifiers>

=item B<apply_after_method_modifiers>

=item B<apply_around_method_modifiers>

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
