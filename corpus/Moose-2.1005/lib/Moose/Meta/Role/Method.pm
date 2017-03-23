
package Moose::Meta::Role::Method;
BEGIN {
  $Moose::Meta::Role::Method::AUTHORITY = 'cpan:STEVAN';
}
{
  $Moose::Meta::Role::Method::VERSION = '2.1005';
}

use strict;
use warnings;

use base 'Moose::Meta::Method';

sub _make_compatible_with {
    my $self = shift;
    my ($other) = @_;

    # XXX: this is pretty gross. the issue here is blah blah blah
    # see the comments in CMOP::Method::Meta and CMOP::Method::Wrapped
    return $self unless $other->_is_compatible_with($self->_real_ref_name);

    return $self->SUPER::_make_compatible_with(@_);
}

1;

# ABSTRACT: A Moose Method metaclass for Roles

__END__

=pod

=head1 NAME

Moose::Meta::Role::Method - A Moose Method metaclass for Roles

=head1 VERSION

version 2.1005

=head1 DESCRIPTION

This is primarily used to mark methods coming from a role
as being different. Right now it is nothing but a subclass
of L<Moose::Meta::Method>.

=head1 BUGS

See L<Moose/BUGS> for details on reporting bugs.

=head1 AUTHOR

Moose is maintained by the Moose Cabal, along with the help of many contributors. See L<Moose/CABAL> and L<Moose/CONTRIBUTORS> for details.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Infinity Interactive, Inc..

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
