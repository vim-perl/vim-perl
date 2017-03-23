
package Moose::Object;
BEGIN {
  $Moose::Object::AUTHORITY = 'cpan:STEVAN';
}
{
  $Moose::Object::VERSION = '2.1005';
}

use strict;
use warnings;

use Carp ();
use Devel::GlobalDestruction ();
use MRO::Compat ();
use Scalar::Util ();
use Try::Tiny ();

use if ( not our $__mx_is_compiled ), 'Moose::Meta::Class';
use if ( not our $__mx_is_compiled ), metaclass => 'Moose::Meta::Class';

sub new {
    my $class = shift;
    my $real_class = Scalar::Util::blessed($class) || $class;

    my $params = $real_class->BUILDARGS(@_);

    return Class::MOP::Class->initialize($real_class)->new_object($params);
}

sub BUILDARGS {
    my $class = shift;
    if ( scalar @_ == 1 ) {
        unless ( defined $_[0] && ref $_[0] eq 'HASH' ) {
            Class::MOP::class_of($class)->throw_error(
                "Single parameters to new() must be a HASH ref",
                data => $_[0] );
        }
        return { %{ $_[0] } };
    }
    elsif ( @_ % 2 ) {
        Carp::carp(
            "The new() method for $class expects a hash reference or a key/value list."
                . " You passed an odd number of arguments" );
        return { @_, undef };
    }
    else {
        return {@_};
    }
}

sub BUILDALL {
    # NOTE: we ask Perl if we even
    # need to do this first, to avoid
    # extra meta level calls
    return unless $_[0]->can('BUILD');
    my ($self, $params) = @_;
    foreach my $method (reverse Class::MOP::class_of($self)->find_all_methods_by_name('BUILD')) {
        $method->{code}->execute($self, $params);
    }
}

sub DEMOLISHALL {
    my $self = shift;
    my ($in_global_destruction) = @_;

    # NOTE: we ask Perl if we even
    # need to do this first, to avoid
    # extra meta level calls
    return unless $self->can('DEMOLISH');

    my @isa;
    if ( my $meta = Class::MOP::class_of($self ) ) {
        @isa = $meta->linearized_isa;
    } else {
        # We cannot count on being able to retrieve a previously made
        # metaclass, _or_ being able to make a new one during global
        # destruction. However, we should still be able to use mro at
        # that time (at least tests suggest so ;)
        my $class_name = ref $self;
        @isa = @{ mro::get_linear_isa($class_name) }
    }

    foreach my $class (@isa) {
        no strict 'refs';
        my $demolish = *{"${class}::DEMOLISH"}{CODE};
        $self->$demolish($in_global_destruction)
            if defined $demolish;
    }
}

sub DESTROY {
    my $self = shift;

    local $?;

    Try::Tiny::try {
        $self->DEMOLISHALL(Devel::GlobalDestruction::in_global_destruction);
    }
    Try::Tiny::catch {
        die $_;
    };

    return;
}

# support for UNIVERSAL::DOES ...
BEGIN {
    my $does = UNIVERSAL->can("DOES") ? "SUPER::DOES" : "isa";
    eval 'sub DOES {
        my ( $self, $class_or_role_name ) = @_;
        return $self->'.$does.'($class_or_role_name)
            || $self->does($class_or_role_name);
    }';
}

# new does() methods will be created
# as appropriate see Moose::Meta::Role
sub does {
    my ($self, $role_name) = @_;
    my $class = Scalar::Util::blessed($self) || $self;
    my $meta = Class::MOP::Class->initialize($class);
    (defined $role_name)
        || $meta->throw_error("You must supply a role name to does()");
    return 1 if $meta->can('does_role') && $meta->does_role($role_name);
    return 0;
}

sub dump {
    my $self = shift;
    require Data::Dumper;
    local $Data::Dumper::Maxdepth = shift if @_;
    Data::Dumper::Dumper $self;
}

1;

# ABSTRACT: The base object for Moose

__END__

=pod

=head1 NAME

Moose::Object - The base object for Moose

=head1 VERSION

version 2.1005

=head1 DESCRIPTION

This class is the default base class for all Moose-using classes. When
you C<use Moose> in this class, your class will inherit from this
class.

It provides a default constructor and destructor, which run all of the
C<BUILD> and C<DEMOLISH> methods in the inheritance hierarchy,
respectively.

You don't actually I<need> to inherit from this in order to use Moose,
but it makes it easier to take advantage of all of Moose's features.

=head1 METHODS

=over 4

=item B<< Moose::Object->new(%params|$params) >>

This method calls C<< $class->BUILDARGS(@_) >>, and then creates a new
instance of the appropriate class. Once the instance is created, it
calls C<< $instance->BUILD($params) >> for each C<BUILD> method in the
inheritance hierarchy.

=item B<< Moose::Object->BUILDARGS(%params|$params) >>

The default implementation of this method accepts a hash or hash
reference of named parameters. If it receives a single argument that
I<isn't> a hash reference it throws an error.

You can override this method in your class to handle other types of
options passed to the constructor.

This method should always return a hash reference of named options.

=item B<< $object->does($role_name) >>

This returns true if the object does the given role.

=item B<< $object->DOES($class_or_role_name) >>

This is a Moose role-aware implementation of L<UNIVERSAL/DOES>.

This is effectively the same as writing:

  $object->does($name) || $object->isa($name)

This method will work with Perl 5.8, which did not implement
C<UNIVERSAL::DOES>.

=item B<< $object->dump($maxdepth) >>

This is a handy utility for C<Data::Dumper>ing an object. By default,
the maximum depth is 1, to avoid making a mess.

=item B<< $object->DESTROY >>

A default destructor is provided, which calls
C<< $instance->DEMOLISH($in_global_destruction) >> for each C<DEMOLISH>
method in the inheritance hierarchy.

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
