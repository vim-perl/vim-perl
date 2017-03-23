
package Class::MOP::Module;
BEGIN {
  $Class::MOP::Module::AUTHORITY = 'cpan:STEVAN';
}
{
  $Class::MOP::Module::VERSION = '2.1005';
}

use strict;
use warnings;

use Carp         'confess';
use Scalar::Util 'blessed';

use base 'Class::MOP::Package';

sub _new {
    my $class = shift;
    return Class::MOP::Class->initialize($class)->new_object(@_)
        if $class ne __PACKAGE__;

    my $params = @_ == 1 ? $_[0] : {@_};
    return bless {
        # Need to quote package to avoid a problem with PPI mis-parsing this
        # as a package statement.

        # from Class::MOP::Package
        'package' => $params->{package},
        namespace => \undef,

        # attributes
        version   => \undef,
        authority => \undef
    } => $class;
}

sub version {
    my $self = shift;
    ${$self->get_or_add_package_symbol('$VERSION')};
}

sub authority {
    my $self = shift;
    ${$self->get_or_add_package_symbol('$AUTHORITY')};
}

sub identifier {
    my $self = shift;
    join '-' => (
        $self->name,
        ($self->version   || ()),
        ($self->authority || ()),
    );
}

sub create {
    my $class = shift;
    my @args = @_;

    unshift @args, 'package' if @args % 2 == 1;
    my %options = @args;

    my $package   = delete $options{package};
    my $version   = delete $options{version};
    my $authority = delete $options{authority};

    my $meta = $class->SUPER::create($package => %options);

    $meta->_instantiate_module($version, $authority);

    return $meta;
}

sub _anon_package_prefix { 'Class::MOP::Module::__ANON__::SERIAL::' }
sub _anon_cache_key      { confess "Modules are not cacheable" }


sub _instantiate_module {
    my($self, $version, $authority) = @_;
    my $package_name = $self->name;

    $self->add_package_symbol('$VERSION' => $version)
        if defined $version;
    $self->add_package_symbol('$AUTHORITY' => $authority)
        if defined $authority;

    return;
}

1;

# ABSTRACT: Module Meta Object

__END__

=pod

=head1 NAME

Class::MOP::Module - Module Meta Object

=head1 VERSION

version 2.1005

=head1 DESCRIPTION

A module is essentially a L<Class::MOP::Package> with metadata, in our
case the version and authority.

=head1 INHERITANCE

B<Class::MOP::Module> is a subclass of L<Class::MOP::Package>.

=head1 METHODS

=over 4

=item B<< Class::MOP::Module->create($package, %options) >>

Overrides C<create> from L<Class::MOP::Package> to provide these additional
options:

=over 4

=item C<version>

A version number, to be installed in the C<$VERSION> package global variable.

=item C<authority>

An authority, to be installed in the C<$AUTHORITY> package global variable.

=back

=item B<< $metamodule->version >>

This is a read-only attribute which returns the C<$VERSION> of the
package, if one exists.

=item B<< $metamodule->authority >>

This is a read-only attribute which returns the C<$AUTHORITY> of the
package, if one exists.

=item B<< $metamodule->identifier >>

This constructs a string which combines the name, version and
authority.

=item B<< Class::MOP::Module->meta >>

This will return a L<Class::MOP::Class> instance for this class.

=back

=head1 AUTHOR

Moose is maintained by the Moose Cabal, along with the help of many contributors. See L<Moose/CABAL> and L<Moose/CONTRIBUTORS> for details.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Infinity Interactive, Inc..

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
