
package Class::MOP::Method;
BEGIN {
  $Class::MOP::Method::AUTHORITY = 'cpan:STEVAN';
}
{
  $Class::MOP::Method::VERSION = '2.1005';
}

use strict;
use warnings;

use Carp         'confess';
use Scalar::Util 'weaken', 'reftype', 'blessed';

use base 'Class::MOP::Object';

# NOTE:
# if poked in the right way,
# they should act like CODE refs.
use overload '&{}' => sub { $_[0]->body }, fallback => 1;

# construction

sub wrap {
    my ( $class, @args ) = @_;

    unshift @args, 'body' if @args % 2 == 1;

    my %params = @args;
    my $code = $params{body};

    if (blessed($code) && $code->isa(__PACKAGE__)) {
        my $method = $code->clone;
        delete $params{body};
        Class::MOP::class_of($class)->rebless_instance($method, %params);
        return $method;
    }
    elsif (!ref $code || 'CODE' ne reftype($code)) {
        confess "You must supply a CODE reference to bless, not (" . ($code || 'undef') . ")";
    }

    ($params{package_name} && $params{name})
        || confess "You must supply the package_name and name parameters";

    my $self = $class->_new(\%params);

    weaken($self->{associated_metaclass}) if $self->{associated_metaclass};

    return $self;
}

sub _new {
    my $class = shift;

    return Class::MOP::Class->initialize($class)->new_object(@_)
        if $class ne __PACKAGE__;

    my $params = @_ == 1 ? $_[0] : {@_};

    return bless {
        'body'                 => $params->{body},
        'associated_metaclass' => $params->{associated_metaclass},
        'package_name'         => $params->{package_name},
        'name'                 => $params->{name},
        'original_method'      => $params->{original_method},
    } => $class;
}

## accessors

sub associated_metaclass { shift->{'associated_metaclass'} }

sub attach_to_class {
    my ( $self, $class ) = @_;
    $self->{associated_metaclass} = $class;
    weaken($self->{associated_metaclass});
}

sub detach_from_class {
    my $self = shift;
    delete $self->{associated_metaclass};
}

sub fully_qualified_name {
    my $self = shift;
    $self->package_name . '::' . $self->name;
}

sub original_method { (shift)->{'original_method'} }

sub _set_original_method { $_[0]->{'original_method'} = $_[1] }

# It's possible that this could cause a loop if there is a circular
# reference in here. That shouldn't ever happen in normal
# circumstances, since original method only gets set when clone is
# called. We _could_ check for such a loop, but it'd involve some sort
# of package-lexical variable, and wouldn't be terribly subclassable.
sub original_package_name {
    my $self = shift;

    $self->original_method
        ? $self->original_method->original_package_name
        : $self->package_name;
}

sub original_name {
    my $self = shift;

    $self->original_method
        ? $self->original_method->original_name
        : $self->name;
}

sub original_fully_qualified_name {
    my $self = shift;

    $self->original_method
        ? $self->original_method->original_fully_qualified_name
        : $self->fully_qualified_name;
}

sub execute {
    my $self = shift;
    $self->body->(@_);
}

# We used to go through use Class::MOP::Class->clone_instance to do this, but
# this was awfully slow. This method may be called a number of times when
# classes are loaded (especially during Moose role application), so it is
# worth optimizing. - DR
sub clone {
    my $self = shift;

    my $clone = bless { %{$self}, @_ }, blessed($self);
    weaken($clone->{associated_metaclass}) if $clone->{associated_metaclass};

    $clone->_set_original_method($self);

    return $clone;
}

1;

# ABSTRACT: Method Meta Object

__END__

=pod

=head1 NAME

Class::MOP::Method - Method Meta Object

=head1 VERSION

version 2.1005

=head1 DESCRIPTION

The Method Protocol is very small, since methods in Perl 5 are just
subroutines in a specific package. We provide a very basic
introspection interface.

=head1 METHODS

=over 4

=item B<< Class::MOP::Method->wrap($code, %options) >>

This is the constructor. It accepts a method body in the form of
either a code reference or a L<Class::MOP::Method> instance, followed
by a hash of options.

The options are:

=over 8

=item * name

The method name (without a package name). This is required if C<$code>
is a coderef.

=item * package_name

The package name for the method. This is required if C<$code> is a
coderef.

=item * associated_metaclass

An optional L<Class::MOP::Class> object. This is the metaclass for the
method's class.

=back

=item B<< $metamethod->clone(%params) >>

This makes a shallow clone of the method object. In particular,
subroutine reference itself is shared between all clones of a given
method.

When a method is cloned, the original method object will be available
by calling C<original_method> on the clone.

=item B<< $metamethod->body >>

This returns a reference to the method's subroutine.

=item B<< $metamethod->name >>

This returns the method's name

=item B<< $metamethod->package_name >>

This returns the method's package name.

=item B<< $metamethod->fully_qualified_name >>

This returns the method's fully qualified name (package name and
method name).

=item B<< $metamethod->associated_metaclass >>

This returns the L<Class::MOP::Class> object for the method, if one
exists.

=item B<< $metamethod->original_method >>

If this method object was created as a clone of some other method
object, this returns the object that was cloned.

=item B<< $metamethod->original_name >>

This returns the method's original name, wherever it was first
defined.

If this method is a clone of a clone (of a clone, etc.), this method
returns the name from the I<first> method in the chain of clones.

=item B<< $metamethod->original_package_name >>

This returns the method's original package name, wherever it was first
defined.

If this method is a clone of a clone (of a clone, etc.), this method
returns the package name from the I<first> method in the chain of
clones.

=item B<< $metamethod->original_fully_qualified_name >>

This returns the method's original fully qualified name, wherever it
was first defined.

If this method is a clone of a clone (of a clone, etc.), this method
returns the fully qualified name from the I<first> method in the chain
of clones.

=item B<< $metamethod->is_stub >>

Returns true if the method is just a stub:

  sub foo;

=item B<< $metamethod->attach_to_class($metaclass) >>

Given a L<Class::MOP::Class> object, this method sets the associated
metaclass for the method. This will overwrite any existing associated
metaclass.

=item B<< $metamethod->detach_from_class >>

Removes any associated metaclass object for the method.

=item B<< $metamethod->execute(...) >>

This executes the method. Any arguments provided will be passed on to
the method itself.

=item B<< Class::MOP::Method->meta >>

This will return a L<Class::MOP::Class> instance for this class.

It should also be noted that L<Class::MOP> will actually bootstrap
this module by installing a number of attribute meta-objects into its
metaclass.

=back

=head1 AUTHOR

Moose is maintained by the Moose Cabal, along with the help of many contributors. See L<Moose/CABAL> and L<Moose/CONTRIBUTORS> for details.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Infinity Interactive, Inc..

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
