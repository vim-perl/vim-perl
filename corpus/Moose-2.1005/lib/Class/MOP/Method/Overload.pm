
package Class::MOP::Method::Overload;
BEGIN {
  $Class::MOP::Method::Overload::AUTHORITY = 'cpan:STEVAN';
}
{
  $Class::MOP::Method::Overload::VERSION = '2.1005';
}

use strict;
use warnings;

use Carp 'confess';

use base 'Class::MOP::Method';

sub wrap {
    my $class = shift;
    my (@args) = @_;
    unshift @args, 'body' if @args % 2 == 1;
    my %params = @args;

    confess "operator is required"
        unless exists $params{operator};

    return $class->SUPER::wrap(
        name => "($params{operator}",
        %params,
    );
}

sub _new {
    my $class = shift;
    return Class::MOP::Class->initialize($class)->new_object(@_)
        if $class ne __PACKAGE__;

    my $params = @_ == 1 ? $_[0] : {@_};

    return bless {
        # inherited from Class::MOP::Method
        'body'                 => $params->{body},
        'associated_metaclass' => $params->{associated_metaclass},
        'package_name'         => $params->{package_name},
        'name'                 => $params->{name},
        'original_method'      => $params->{original_method},

        # defined in this class
        'operator'             => $params->{operator},
    } => $class;
}

1;

# ABSTRACT: Method Meta Object for methods which implement overloading

__END__

=pod

=head1 NAME

Class::MOP::Method::Overload - Method Meta Object for methods which implement overloading

=head1 VERSION

version 2.1005

=head1 DESCRIPTION

This is a L<Class::MOP::Method> subclass which represents methods that
implement overloading.

=head1 METHODS

=over 4

=item B<< Class::MOP::Method::Overload->wrap($metamethod, %options) >>

This is the constructor. The options accepted are identical to the ones
accepted by L<Class::MOP::Method>, except that it also required an C<operator>
parameter, which should be an operator as defined by the L<overload> pragma.

=item B<< $metamethod->operator >>

This returns the operator that was passed to new.

=back

=head1 AUTHOR

Moose is maintained by the Moose Cabal, along with the help of many contributors. See L<Moose/CABAL> and L<Moose/CONTRIBUTORS> for details.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Infinity Interactive, Inc..

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
