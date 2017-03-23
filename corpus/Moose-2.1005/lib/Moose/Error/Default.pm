package Moose::Error::Default;
BEGIN {
  $Moose::Error::Default::AUTHORITY = 'cpan:STEVAN';
}
{
  $Moose::Error::Default::VERSION = '2.1005';
}

use strict;
use warnings;

use Carp::Heavy;
use Class::MOP::MiniTrait;

use Moose::Error::Util;

use base 'Class::MOP::Object';

Class::MOP::MiniTrait::apply(__PACKAGE__, 'Moose::Meta::Object::Trait');

sub new {
    my ( $self, @args ) = @_;
    # can't use Moose::Error::Util::create_error here because that would break
    # inheritance. we don't care about that for the inlined version, because
    # the inlined versions are explicitly not inherited.
    if (defined $ENV{MOOSE_ERROR_STYLE} && $ENV{MOOSE_ERROR_STYLE} eq 'croak') {
        $self->create_error_croak( @args );
    }
    else {
        $self->create_error_confess( @args );
    }
}

sub _inline_new {
    my ( $self, %args ) = @_;

    my $depth = ($args{depth} || 0) - 1;
    return 'Moose::Error::Util::create_error('
      . 'message => ' . $args{message} . ', '
      . 'depth   => ' . $depth         . ', '
  . ')';
}

sub create_error_croak {
    my ( $self, @args ) = @_;
    return Moose::Error::Util::create_error_croak(@args);
}

sub create_error_confess {
    my ( $self, @args ) = @_;
    return Moose::Error::Util::create_error_confess(@args);
}

1;

# ABSTRACT: L<Carp> based error generation for Moose.

__END__

=pod

=head1 NAME

Moose::Error::Default - L<Carp> based error generation for Moose.

=head1 VERSION

version 2.1005

=head1 DESCRIPTION

This class implements L<Carp> based error generation.

The default behavior is like L<Moose::Error::Confess>. To override this to
default to L<Moose::Error::Croak>'s behaviour on a system wide basis, set the
MOOSE_ERROR_STYLE environment variable to C<croak>. The use of this
environment variable is considered experimental, and may change in a future
release.

=head1 METHODS

=over 4

=item B<< Moose::Error::Default->new(@args) >>

Create a new error. Delegates to C<create_error_confess> or
C<create_error_croak>.

=item B<< $error->create_error_confess(@args) >>

=item B<< $error->create_error_croak(@args) >>

Creates a new errors string of the specified style.

=back

=head1 AUTHOR

Moose is maintained by the Moose Cabal, along with the help of many contributors. See L<Moose/CABAL> and L<Moose/CONTRIBUTORS> for details.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Infinity Interactive, Inc..

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
