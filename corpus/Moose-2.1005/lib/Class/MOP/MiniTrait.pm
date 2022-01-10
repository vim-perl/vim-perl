package Class::MOP::MiniTrait;
BEGIN {
  $Class::MOP::MiniTrait::AUTHORITY = 'cpan:STEVAN';
}
{
  $Class::MOP::MiniTrait::VERSION = '2.1005';
}

use strict;
use warnings;

use Class::Load qw(load_class);

sub apply {
    my ( $to_class, $trait ) = @_;

    for ( grep { !ref } $to_class, $trait ) {
        load_class($_);
        $_ = Class::MOP::Class->initialize($_);
    }

    for my $meth ( grep { $_->package_name ne 'UNIVERSAL' } $trait->get_all_methods ) {
        my $meth_name = $meth->name;

        if ( $to_class->find_method_by_name($meth_name) ) {
            $to_class->add_around_method_modifier( $meth_name, $meth->body );
        }
        else {
            $to_class->add_method( $meth_name, $meth->clone );
        }
    }
}

# We can't load this with use, since it may be loaded and used from Class::MOP
# (via CMOP::Class, etc). However, if for some reason this module is loaded
# _without_ first loading Class::MOP we need to require Class::MOP so we can
# use it and CMOP::Class.
require Class::MOP;

1;

# ABSTRACT: Extremely limited trait application

__END__

=pod

=head1 NAME

Class::MOP::MiniTrait - Extremely limited trait application

=head1 VERSION

version 2.1005

=head1 DESCRIPTION

This package provides a single function, C<apply>, which does a half-assed job
of applying a trait to a class. It exists solely for use inside Class::MOP and
L<Moose> core classes.

=head1 AUTHOR

Moose is maintained by the Moose Cabal, along with the help of many contributors. See L<Moose/CABAL> and L<Moose/CONTRIBUTORS> for details.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Infinity Interactive, Inc..

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
