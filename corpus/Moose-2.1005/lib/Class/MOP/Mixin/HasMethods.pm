package Class::MOP::Mixin::HasMethods;
BEGIN {
  $Class::MOP::Mixin::HasMethods::AUTHORITY = 'cpan:STEVAN';
}
{
  $Class::MOP::Mixin::HasMethods::VERSION = '2.1005';
}

use strict;
use warnings;

use Class::MOP::Method::Meta;
use Class::MOP::Method::Overload;

use Scalar::Util 'blessed', 'reftype';
use Carp         'confess';
use Sub::Name    'subname';

use overload ();

use base 'Class::MOP::Mixin';

sub _meta_method_class { 'Class::MOP::Method::Meta' }

sub _add_meta_method {
    my $self = shift;
    my ($name) = @_;
    my $existing_method = $self->can('find_method_by_name')
                              ? $self->find_method_by_name($name)
                              : $self->get_method($name);
    return if $existing_method
           && $existing_method->isa($self->_meta_method_class);
    $self->add_method(
        $name => $self->_meta_method_class->wrap(
            name                 => $name,
            package_name         => $self->name,
            associated_metaclass => $self,
        )
    );
}

sub wrap_method_body {
    my ( $self, %args ) = @_;

    ( 'CODE' eq reftype $args{body} )
        || confess "Your code block must be a CODE reference";

    $self->method_metaclass->wrap(
        package_name => $self->name,
        %args,
    );
}

sub add_method {
    my ( $self, $method_name, $method ) = @_;
    ( defined $method_name && length $method_name )
        || confess "You must define a method name";

    my $package_name = $self->name;

    my $body;
    if ( blessed($method) && $method->isa('Class::MOP::Method') ) {
        $body = $method->body;
        if ( $method->package_name ne $package_name ) {
            $method = $method->clone(
                package_name => $package_name,
                name         => $method_name,
            );
        }

        $method->attach_to_class($self);
    }
    else {
        # If a raw code reference is supplied, its method object is not created.
        # The method object won't be created until required.
        $body = $method;
    }

    $self->_method_map->{$method_name} = $method;

    my ($current_package, $current_name) = Class::MOP::get_code_info($body);

    subname($package_name . '::' . $method_name, $body)
        unless defined $current_name && $current_name !~ /^__ANON__/;

    $self->add_package_symbol("&$method_name", $body);

    # we added the method to the method map too, so it's still valid
    $self->update_package_cache_flag;
}

sub _code_is_mine {
    my ( $self, $code ) = @_;

    my ( $code_package, $code_name ) = Class::MOP::get_code_info($code);

    return ( $code_package && $code_package eq $self->name )
        || ( $code_package eq 'constant' && $code_name eq '__ANON__' );
}

sub has_method {
    my ( $self, $method_name ) = @_;

    ( defined $method_name && length $method_name )
        || confess "You must define a method name";

    my $method = $self->_get_maybe_raw_method($method_name)
        or return;

    return defined($self->_method_map->{$method_name} = $method);
}

sub get_method {
    my ( $self, $method_name ) = @_;

    ( defined $method_name && length $method_name )
        || confess "You must define a method name";

    my $method = $self->_get_maybe_raw_method($method_name)
        or return;

    return $method if blessed($method) && $method->isa('Class::MOP::Method');

    return $self->_method_map->{$method_name} = $self->wrap_method_body(
        body                 => $method,
        name                 => $method_name,
        associated_metaclass => $self,
    );
}

sub _get_maybe_raw_method {
    my ( $self, $method_name ) = @_;

    my $map_entry = $self->_method_map->{$method_name};
    return $map_entry if defined $map_entry;

    my $code = $self->get_package_symbol("&$method_name");

    return unless $code && $self->_code_is_mine($code);

    return $code;
}

sub remove_method {
    my ( $self, $method_name ) = @_;

    ( defined $method_name && length $method_name )
        || confess "You must define a method name";

    my $removed_method = delete $self->_method_map->{$method_name};

    $self->remove_package_symbol("&$method_name");

    $removed_method->detach_from_class
        if blessed($removed_method) && $removed_method->isa('Class::MOP::Method');

    # still valid, since we just removed the method from the map
    $self->update_package_cache_flag;

    return $removed_method;
}

sub get_method_list {
    my $self = shift;

    return keys %{ $self->_full_method_map };
}

sub _get_local_methods {
    my $self = shift;

    return values %{ $self->_full_method_map };
}

sub _restore_metamethods_from {
    my $self = shift;
    my ($old_meta) = @_;

    for my $method ($old_meta->_get_local_methods) {
        $method->_make_compatible_with($self->method_metaclass);
        $self->add_method($method->name => $method);
    }
}

sub reset_package_cache_flag  { (shift)->{'_package_cache_flag'} = undef }
sub update_package_cache_flag {
    my $self = shift;
    # NOTE:
    # we can manually update the cache number
    # since we are actually adding the method
    # to our cache as well. This avoids us
    # having to regenerate the method_map.
    # - SL
    $self->{'_package_cache_flag'} = Class::MOP::check_package_cache_flag($self->name);
}

sub _full_method_map {
    my $self = shift;

    my $pkg_gen = Class::MOP::check_package_cache_flag($self->name);

    if (($self->{_package_cache_flag_full} || -1) != $pkg_gen) {
        # forcibly reify all method map entries
        $self->get_method($_)
            for $self->list_all_package_symbols('CODE');
        $self->{_package_cache_flag_full} = $pkg_gen;
    }

    return $self->_method_map;
}

# overloading

my $overload_operators;
sub overload_operators {
    $overload_operators ||= [map { split /\s+/ } values %overload::ops];
    return @$overload_operators;
}

sub is_overloaded {
    my $self = shift;
    return overload::Overloaded($self->name);
}

# XXX this could probably stand to be cached, but i figure it should be
# uncommon enough to not particularly matter
sub _overload_map {
    my $self = shift;

    return {} unless $self->is_overloaded;

    my %map;
    for my $op ($self->overload_operators) {
        my $body = $self->_get_overloaded_operator_body($op);
        next unless defined $body;
        $map{$op} = $body;
    }

    return \%map;
}

sub get_overload_list {
    my $self = shift;
    return keys %{ $self->_overload_map };
}

sub get_all_overloaded_operators {
    my $self = shift;
    my $map = $self->_overload_map;
    return map { $self->_wrap_overload($_, $map->{$_}) } keys %$map;
}

sub has_overloaded_operator {
    my $self = shift;
    my ($op) = @_;
    return defined $self->_get_overloaded_operator_body($op);
}

sub get_overloaded_operator {
    my $self = shift;
    my ($op) = @_;
    my $body = $self->_get_overloaded_operator_body($op);
    return unless defined $body;
    return $self->_wrap_overload($op, $body);
}

sub add_overloaded_operator {
    my $self = shift;
    my ($op, $body) = @_;
    $self->name->overload::OVERLOAD($op => $body);
}

sub remove_overloaded_operator {
    my $self = shift;
    my ($op) = @_;

    if ( $] < 5.018 ) {
        # ugh, overload.pm provides no api for this - but the problem that
        # makes this necessary has been fixed in 5.18
        $self->get_or_add_package_symbol('%OVERLOAD')->{dummy}++;
    }

    $self->remove_package_symbol('&(' . $op);
}

sub _get_overloaded_operator_body {
    my $self = shift;
    my ($op) = @_;
    return overload::Method($self->name, $op);
}

sub _wrap_overload {
    my $self = shift;
    my ($op, $body) = @_;
    return Class::MOP::Method::Overload->wrap(
        operator             => $op,
        package_name         => $self->name,
        associated_metaclass => $self,
        body                 => $body,
    );
}

1;

# ABSTRACT: Methods for metaclasses which have methods

__END__

=pod

=head1 NAME

Class::MOP::Mixin::HasMethods - Methods for metaclasses which have methods

=head1 VERSION

version 2.1005

=head1 DESCRIPTION

This class implements methods for metaclasses which have methods
(L<Class::MOP::Package> and L<Moose::Meta::Role>). See L<Class::MOP::Package>
for API details.

=head1 AUTHOR

Moose is maintained by the Moose Cabal, along with the help of many contributors. See L<Moose/CABAL> and L<Moose/CONTRIBUTORS> for details.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Infinity Interactive, Inc..

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
