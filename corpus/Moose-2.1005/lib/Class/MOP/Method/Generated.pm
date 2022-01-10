
package Class::MOP::Method::Generated;
BEGIN {
  $Class::MOP::Method::Generated::AUTHORITY = 'cpan:STEVAN';
}
{
  $Class::MOP::Method::Generated::VERSION = '2.1005';
}

use strict;
use warnings;

use Carp 'confess';
use Eval::Closure;

use base 'Class::MOP::Method';

## accessors

sub new {
    confess __PACKAGE__ . " is an abstract base class, you must provide a constructor.";
}

sub _initialize_body {
    confess "No body to initialize, " . __PACKAGE__ . " is an abstract base class";
}

sub _generate_description {
    my ( $self, $context ) = @_;
    $context ||= $self->definition_context;

    my $desc = "generated method";
    my $origin = "unknown origin";

    if (defined $context) {
        if (defined $context->{description}) {
            $desc = $context->{description};
        }

        if (defined $context->{file} || defined $context->{line}) {
            $origin = "defined at "
                    . (defined $context->{file}
                        ? $context->{file} : "<unknown file>")
                    . " line "
                    . (defined $context->{line}
                        ? $context->{line} : "<unknown line>");
        }
    }

    return "$desc ($origin)";
}

sub _compile_code {
    my ( $self, @args ) = @_;
    unshift @args, 'source' if @args % 2;
    my %args = @args;

    my $context = delete $args{context};
    my $environment = $self->can('_eval_environment')
        ? $self->_eval_environment
        : {};

    return eval_closure(
        environment => $environment,
        description => $self->_generate_description($context),
        %args,
    );
}

1;

# ABSTRACT: Abstract base class for generated methods

__END__

=pod

=head1 NAME

Class::MOP::Method::Generated - Abstract base class for generated methods

=head1 VERSION

version 2.1005

=head1 DESCRIPTION

This is a C<Class::MOP::Method> subclass which is subclassed by
C<Class::MOP::Method::Accessor> and
C<Class::MOP::Method::Constructor>.

It is not intended to be used directly.

=head1 AUTHOR

Moose is maintained by the Moose Cabal, along with the help of many contributors. See L<Moose/CABAL> and L<Moose/CONTRIBUTORS> for details.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Infinity Interactive, Inc..

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
