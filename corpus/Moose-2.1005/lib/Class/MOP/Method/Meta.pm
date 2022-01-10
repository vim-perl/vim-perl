
package Class::MOP::Method::Meta;
BEGIN {
  $Class::MOP::Method::Meta::AUTHORITY = 'cpan:STEVAN';
}
{
  $Class::MOP::Method::Meta::VERSION = '2.1005';
}

use strict;
use warnings;

use Carp         'confess';
use Scalar::Util 'blessed', 'weaken';

use constant DEBUG_NO_META => $ENV{DEBUG_NO_META} ? 1 : 0;

use base 'Class::MOP::Method';

sub _is_caller_mop_internal {
    my $self = shift;
    my ($caller) = @_;
    return $caller =~ /^(?:Class::MOP|metaclass)(?:::|$)/;
}

sub _generate_meta_method {
    my $method_self = shift;
    my $metaclass   = shift;
    weaken($metaclass);

    sub {
        # this will be compiled out if the env var wasn't set
        if (DEBUG_NO_META) {
            confess "'meta' method called by MOP internals"
                # it's okay to call meta methods on metaclasses, since we
                # explicitly ask for them
                if !$_[0]->isa('Class::MOP::Object')
                && !$_[0]->isa('Class::MOP::Mixin')
                # it's okay if the test itself calls ->meta, we only care about
                # if the mop internals call ->meta
                && $method_self->_is_caller_mop_internal(scalar caller);
        }
        # we must re-initialize so that it
        # works as expected in subclasses,
        # since metaclass instances are
        # singletons, this is not really a
        # big deal anyway.
        $metaclass->initialize(blessed($_[0]) || $_[0])
    };
}

sub wrap {
    my ($class, @args) = @_;

    unshift @args, 'body' if @args % 2 == 1;
    my %params = @args;
    confess "Overriding the body of meta methods is not allowed"
        if $params{body};

    my $metaclass_class = $params{associated_metaclass}->meta;
    $params{body} = $class->_generate_meta_method($metaclass_class);
    return $class->SUPER::wrap(%params);
}

sub _make_compatible_with {
    my $self = shift;
    my ($other) = @_;

    # XXX: this is pretty gross. the issue here is that CMOP::Method::Meta
    # objects are subclasses of CMOP::Method, but when we get to moose, they'll
    # need to be compatible with Moose::Meta::Method, which isn't possible. the
    # right solution here is to make ::Meta into a role that gets applied to
    # whatever the method_metaclass happens to be and get rid of
    # _meta_method_metaclass entirely, but that's not going to happen until
    # we ditch cmop and get roles into the bootstrapping, so. i'm not
    # maintaining the previous behavior of turning them into instances of the
    # new method_metaclass because that's equally broken, and at least this way
    # any issues will at least be detectable and potentially fixable. -doy
    return $self unless $other->_is_compatible_with($self->_real_ref_name);

    return $self->SUPER::_make_compatible_with(@_);
}

1;

# ABSTRACT: Method Meta Object for C<meta> methods

__END__

=pod

=head1 NAME

Class::MOP::Method::Meta - Method Meta Object for C<meta> methods

=head1 VERSION

version 2.1005

=head1 DESCRIPTION

This is a L<Class::MOP::Method> subclass which represents C<meta>
methods installed into classes by Class::MOP.

=head1 METHODS

=over 4

=item B<< Class::MOP::Method::Wrapped->wrap($metamethod, %options) >>

This is the constructor. It accepts a L<Class::MOP::Method> object and
a hash of options. The options accepted are identical to the ones
accepted by L<Class::MOP::Method>, except that C<body> cannot be passed
(it will be generated automatically).

=back

=head1 AUTHOR

Moose is maintained by the Moose Cabal, along with the help of many contributors. See L<Moose/CABAL> and L<Moose/CONTRIBUTORS> for details.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Infinity Interactive, Inc..

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
