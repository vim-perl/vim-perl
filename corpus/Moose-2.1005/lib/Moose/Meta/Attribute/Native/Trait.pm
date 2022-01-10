
package Moose::Meta::Attribute::Native::Trait;
BEGIN {
  $Moose::Meta::Attribute::Native::Trait::AUTHORITY = 'cpan:STEVAN';
}
{
  $Moose::Meta::Attribute::Native::Trait::VERSION = '2.1005';
}
use Moose::Role;

use Class::Load qw(load_class);
use List::MoreUtils qw( any uniq );
use Moose::Deprecated;
use Moose::Util;
use Moose::Util::TypeConstraints;

requires '_helper_type';

has _used_default_is => (
    is      => 'rw',
    isa     => 'Bool',
    default => 0,
);

before '_process_options' => sub {
    my ( $self, $name, $options ) = @_;

    $self->_check_helper_type( $options, $name );

    if ( !( any { exists $options->{$_} } qw( is reader writer accessor ) )
        && $self->can('_default_is') ) {

        $options->{is} = $self->_default_is;

        $options->{_used_default_is} = 1;
    }

    if (
        !(
            $options->{required}
            || any { exists $options->{$_} } qw( default builder lazy_build )
        )
        && $self->can('_default_default')
        ) {

        $options->{default} = $self->_default_default;

        Moose::Deprecated::deprecated(
            feature => 'default default for Native Trait',
            message =>
                'Allowing a native trait to automatically supply a default is deprecated.'
                . ' You can avoid this warning by supplying a default, builder, or making the attribute required'
        );
    }
};

after 'install_accessors' => sub {
    my $self = shift;

    return unless $self->_used_default_is;

    my @methods
        = $self->_default_is eq 'rw'
        ? qw( reader writer accessor )
        : 'reader';

    my $name = $self->name;
    my $class = $self->associated_class->name;

    for my $meth ( uniq grep {defined} map { $self->$_ } @methods ) {

        my $message
            = "The $meth method in the $class class was automatically created"
            . " by the native delegation trait for the $name attribute."
            . q{ This "default is" feature is deprecated.}
            . q{ Explicitly set "is" or define accessor names to avoid this};

        $self->associated_class->add_before_method_modifier(
            $meth => sub {
                Moose::Deprecated::deprecated(
                    feature => 'default is for Native Trait',
                    message =>$message,
                );
            }
        );
    }
    };

sub _check_helper_type {
    my ( $self, $options, $name ) = @_;

    my $type = $self->_helper_type;

    $options->{isa} = $type
        unless exists $options->{isa};

    my $isa;
    my $isa_name;

    if (
        Moose::Util::does_role(
            $options->{isa}, 'Specio::Constraint::Role::Interface'
        )
        ) {

        $isa = $options->{isa};
        require Specio::Library::Builtins;
        return if $isa->is_a_type_of( Specio::Library::Builtins::t($type) );
        $isa_name = $isa->name() || $isa->description();
    }
    else {
        $isa = Moose::Util::TypeConstraints::find_or_create_type_constraint(
            $options->{isa} );
        return if $isa->is_a_type_of($type);
        $isa_name = $isa->name();
    }

    confess
        "The type constraint for $name must be a subtype of $type but it's a $isa_name";
}

before 'install_accessors' => sub { (shift)->_check_handles_values };

sub _check_handles_values {
    my $self = shift;

    my %handles = $self->_canonicalize_handles;

    for my $original_method ( values %handles ) {
        my $name = $original_method->[0];

        my $accessor_class = $self->_native_accessor_class_for($name);

        ( $accessor_class && $accessor_class->can('new') )
            || confess
            "$name is an unsupported method type - $accessor_class";
    }
}

around '_canonicalize_handles' => sub {
    shift;
    my $self    = shift;
    my $handles = $self->handles;

    return unless $handles;

    unless ( 'HASH' eq ref $handles ) {
        $self->throw_error(
            "The 'handles' option must be a HASH reference, not $handles");
    }

    return
        map { $_ => $self->_canonicalize_handles_value( $handles->{$_} ) }
        keys %$handles;
};

sub _canonicalize_handles_value {
    my $self  = shift;
    my $value = shift;

    if ( ref $value && 'ARRAY' ne ref $value ) {
        $self->throw_error(
            "All values passed to handles must be strings or ARRAY references, not $value"
        );
    }

    return ref $value ? $value : [$value];
}

around '_make_delegation_method' => sub {
    my $next = shift;
    my ( $self, $handle_name, $method_to_call ) = @_;

    my ( $name, @curried_args ) = @$method_to_call;

    my $accessor_class = $self->_native_accessor_class_for($name);

    die "Cannot find an accessor class for $name"
        unless $accessor_class && $accessor_class->can('new');

    return $accessor_class->new(
        name               => $handle_name,
        package_name       => $self->associated_class->name,
        delegate_to_method => $name,
        attribute          => $self,
        is_inline          => 1,
        curried_arguments  => \@curried_args,
        root_types         => [ $self->_root_types ],
    );
};

sub _root_types {
    return $_[0]->_helper_type;
}

sub _native_accessor_class_for {
    my ( $self, $suffix ) = @_;

    my $role
        = 'Moose::Meta::Method::Accessor::Native::'
        . $self->_native_type . '::'
        . $suffix;

    load_class($role);
    return Moose::Meta::Class->create_anon_class(
        superclasses =>
            [ $self->accessor_metaclass, $self->delegation_metaclass ],
        roles => [$role],
        cache => 1,
    )->name;
}

sub _build_native_type {
    my $self = shift;

    for my $role_name ( map { $_->name } $self->meta->calculate_all_roles ) {
        return $1 if $role_name =~ /::Native::Trait::(\w+)$/;
    }

    die "Cannot calculate native type for " . ref $self;
}

has '_native_type' => (
    is      => 'ro',
    isa     => 'Str',
    lazy    => 1,
    builder => '_build_native_type',
);

no Moose::Role;
no Moose::Util::TypeConstraints;

1;

# ABSTRACT: Shared role for native delegation traits

__END__

=pod

=head1 NAME

Moose::Meta::Attribute::Native::Trait - Shared role for native delegation traits

=head1 VERSION

version 2.1005

=head1 BUGS

See L<Moose/BUGS> for details on reporting bugs.

=head1 SEE ALSO

Documentation for Moose native traits can be found in
L<Moose::Meta::Attribute::Native>.

=head1 AUTHOR

Moose is maintained by the Moose Cabal, along with the help of many contributors. See L<Moose/CABAL> and L<Moose/CONTRIBUTORS> for details.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Infinity Interactive, Inc..

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
