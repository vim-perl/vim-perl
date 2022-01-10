
package Moose::Meta::Method::Constructor;
BEGIN {
  $Moose::Meta::Method::Constructor::AUTHORITY = 'cpan:STEVAN';
}
{
  $Moose::Meta::Method::Constructor::VERSION = '2.1005';
}

use strict;
use warnings;

use Carp ();
use List::MoreUtils 'any';
use Scalar::Util 'blessed', 'weaken', 'looks_like_number', 'refaddr';
use Try::Tiny;

use base 'Moose::Meta::Method',
         'Class::MOP::Method::Constructor';

sub new {
    my $class   = shift;
    my %options = @_;

    my $meta = $options{metaclass};

    (ref $options{options} eq 'HASH')
        || $class->throw_error("You must pass a hash of options", data => $options{options});

    ($options{package_name} && $options{name})
        || $class->throw_error("You must supply the package_name and name parameters $Class::MOP::Method::UPGRADE_ERROR_TEXT");

    my $self = bless {
        'body'          => undef,
        'package_name'  => $options{package_name},
        'name'          => $options{name},
        'options'       => $options{options},
        'associated_metaclass' => $meta,
        'definition_context' => $options{definition_context},
        '_expected_method_class' => $options{_expected_method_class} || 'Moose::Object',
    } => $class;

    # we don't want this creating
    # a cycle in the code, if not
    # needed
    weaken($self->{'associated_metaclass'});

    $self->_initialize_body;

    return $self;
}

## method

sub _initialize_body {
    my $self = shift;
    $self->{'body'} = $self->_generate_constructor_method_inline;
}

1;

# ABSTRACT: Method Meta Object for constructors

__END__

=pod

=head1 NAME

Moose::Meta::Method::Constructor - Method Meta Object for constructors

=head1 VERSION

version 2.1005

=head1 DESCRIPTION

This class is a subclass of L<Class::MOP::Method::Constructor> that
provides additional Moose-specific functionality

To understand this class, you should read the the
L<Class::MOP::Method::Constructor> documentation as well.

=head1 INHERITANCE

C<Moose::Meta::Method::Constructor> is a subclass of
L<Moose::Meta::Method> I<and> L<Class::MOP::Method::Constructor>.

=head1 BUGS

See L<Moose/BUGS> for details on reporting bugs.

=head1 AUTHOR

Moose is maintained by the Moose Cabal, along with the help of many contributors. See L<Moose/CABAL> and L<Moose/CONTRIBUTORS> for details.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Infinity Interactive, Inc..

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
