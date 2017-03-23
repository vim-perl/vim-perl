package Class::MOP::Deprecated;
BEGIN {
  $Class::MOP::Deprecated::AUTHORITY = 'cpan:STEVAN';
}
{
  $Class::MOP::Deprecated::VERSION = '2.1005';
}

use strict;
use warnings;

use Package::DeprecationManager -deprecations => {
};

1;

# ABSTRACT: Manages deprecation warnings for Class::MOP

__END__

=pod

=head1 NAME

Class::MOP::Deprecated - Manages deprecation warnings for Class::MOP

=head1 VERSION

version 2.1005

=head1 DESCRIPTION

    use Class::MOP::Deprecated -api_version => $version;

=head1 FUNCTIONS

This module manages deprecation warnings for features that have been
deprecated in Class::MOP.

If you specify C<< -api_version => $version >>, you can use deprecated features
without warnings. Note that this special treatment is limited to the package
that loads C<Class::MOP::Deprecated>.

=head1 AUTHOR

Moose is maintained by the Moose Cabal, along with the help of many contributors. See L<Moose/CABAL> and L<Moose/CONTRIBUTORS> for details.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Infinity Interactive, Inc..

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
