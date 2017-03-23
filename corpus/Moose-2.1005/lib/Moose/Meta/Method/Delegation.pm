
package Moose::Meta::Method::Delegation;
BEGIN {
  $Moose::Meta::Method::Delegation::AUTHORITY = 'cpan:STEVAN';
}
{
  $Moose::Meta::Method::Delegation::VERSION = '2.1005';
}

use strict;
use warnings;

use Carp         'confess';
use Scalar::Util 'blessed', 'weaken';

use base 'Moose::Meta::Method',
         'Class::MOP::Method::Generated';


sub new {
    my $class   = shift;
    my %options = @_;

    ( exists $options{attribute} )
        || confess "You must supply an attribute to construct with";

    ( blessed( $options{attribute} )
            && $options{attribute}->isa('Moose::Meta::Attribute') )
        || confess
        "You must supply an attribute which is a 'Moose::Meta::Attribute' instance";

    ( $options{package_name} && $options{name} )
        || confess
        "You must supply the package_name and name parameters $Class::MOP::Method::UPGRADE_ERROR_TEXT";

    ( $options{delegate_to_method} && ( !ref $options{delegate_to_method} )
            || ( 'CODE' eq ref $options{delegate_to_method} ) )
        || confess
        'You must supply a delegate_to_method which is a method name or a CODE reference';

    exists $options{curried_arguments}
        || ( $options{curried_arguments} = [] );

    ( $options{curried_arguments} &&
        ( 'ARRAY' eq ref $options{curried_arguments} ) )
        || confess 'You must supply a curried_arguments which is an ARRAY reference';

    my $self = $class->_new( \%options );

    weaken( $self->{'attribute'} );

    $self->_initialize_body;

    return $self;
}

sub _new {
    my $class = shift;
    my $options = @_ == 1 ? $_[0] : {@_};

    return bless $options, $class;
}

sub curried_arguments { (shift)->{'curried_arguments'} }

sub associated_attribute { (shift)->{'attribute'} }

sub delegate_to_method { (shift)->{'delegate_to_method'} }

sub _initialize_body {
    my $self = shift;

    my $method_to_call = $self->delegate_to_method;
    return $self->{body} = $method_to_call
        if ref $method_to_call;

    my $accessor = $self->_get_delegate_accessor;

    my $handle_name = $self->name;

    # NOTE: we used to do a goto here, but the goto didn't handle
    # failure correctly (it just returned nothing), so I took that
    # out. However, the more I thought about it, the less I liked it
    # doing the goto, and I preferred the act of delegation being
    # actually represented in the stack trace.  - SL
    # not inlining this, since it won't really speed things up at
    # all... the only thing that would end up different would be
    # interpolating in $method_to_call, and a bunch of things in the
    # error handling that mostly never gets called - doy
    $self->{body} = sub {
        my $instance = shift;
        my $proxy    = $instance->$accessor();

        my $error
            = !defined $proxy                 ? ' is not defined'
            : ref($proxy) && !blessed($proxy) ? qq{ is not an object (got '$proxy')}
            : undef;

        if ($error) {
            $self->throw_error(
                "Cannot delegate $handle_name to $method_to_call because "
                    . "the value of "
                    . $self->associated_attribute->name
                    . $error,
                method_name => $method_to_call,
                object      => $instance
            );
        }
        unshift @_, @{ $self->curried_arguments };
        $proxy->$method_to_call(@_);
    };
}

sub _get_delegate_accessor {
    my $self = shift;
    my $attr = $self->associated_attribute;

    # NOTE:
    # always use a named method when
    # possible, if you use the method
    # ref and there are modifiers on
    # the accessors then it will not
    # pick up the modifiers too. Only
    # the named method will assure that
    # we also have any modifiers run.
    # - SL
    my $accessor = $attr->has_read_method
        ? $attr->get_read_method
        : $attr->get_read_method_ref;

    $accessor = $accessor->body if Scalar::Util::blessed $accessor;

    return $accessor;
}

1;

# ABSTRACT: A Moose Method metaclass for delegation methods

__END__

=pod

=head1 NAME

Moose::Meta::Method::Delegation - A Moose Method metaclass for delegation methods

=head1 VERSION

version 2.1005

=head1 DESCRIPTION

This is a subclass of L<Moose::Meta::Method> for delegation
methods.

=head1 METHODS

=over 4

=item B<< Moose::Meta::Method::Delegation->new(%options) >>

This creates the delegation methods based on the provided C<%options>.

=over 4

=item I<attribute>

This must be an instance of C<Moose::Meta::Attribute> which this
accessor is being generated for. This options is B<required>.

=item I<delegate_to_method>

The method in the associated attribute's value to which we
delegate. This can be either a method name or a code reference.

=item I<curried_arguments>

An array reference of arguments that will be prepended to the argument list for
any call to the delegating method.

=back

=item B<< $metamethod->associated_attribute >>

Returns the attribute associated with this method.

=item B<< $metamethod->curried_arguments >>

Return any curried arguments that will be passed to the delegated method.

=item B<< $metamethod->delegate_to_method >>

Returns the method to which this method delegates, as passed to the
constructor.

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
