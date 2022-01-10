
package Moose::Meta::Method::Meta;
BEGIN {
  $Moose::Meta::Method::Meta::AUTHORITY = 'cpan:STEVAN';
}
{
  $Moose::Meta::Method::Meta::VERSION = '2.1005';
}

use strict;
use warnings;

use base 'Moose::Meta::Method',
         'Class::MOP::Method::Meta';

sub _is_caller_mop_internal {
    my $self = shift;
    my ($caller) = @_;
    return 1 if $caller =~ /^Moose(?:::|$)/;
    return $self->SUPER::_is_caller_mop_internal($caller);
}

# XXX: ugh multiple inheritance
sub wrap {
    my $class = shift;
    return $class->Class::MOP::Method::Meta::wrap(@_);
}

sub _make_compatible_with {
    my $self = shift;
    return $self->Class::MOP::Method::Meta::_make_compatible_with(@_);
}

1;

# ABSTRACT: A Moose Method metaclass for C<meta> methods

__END__

=pod

=head1 NAME

Moose::Meta::Method::Meta - A Moose Method metaclass for C<meta> methods

=head1 VERSION

version 2.1005

=head1 DESCRIPTION

This class is a subclass of L<Class::MOP::Method::Meta> that
provides additional Moose-specific functionality, all of which is
private.

To understand this class, you should read the the
L<Class::MOP::Method::Meta> documentation.

=head1 BUGS

See L<Moose/BUGS> for details on reporting bugs.

=head1 AUTHOR

Moose is maintained by the Moose Cabal, along with the help of many contributors. See L<Moose/CABAL> and L<Moose/CONTRIBUTORS> for details.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Infinity Interactive, Inc..

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
