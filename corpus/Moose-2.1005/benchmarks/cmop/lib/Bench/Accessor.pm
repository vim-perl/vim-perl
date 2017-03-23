#!/usr/bin/perl

package Bench::Accessor;
use Moose;
use Moose::Util::TypeConstraints;

eval {
coerce ArrayRef
    => from HashRef
        => via { [ %$_ ] };
};

has class => (
    isa => "Str",
    is  => "ro",
);

has construct => (
    isa => "ArrayRef",
    is  => "ro",
    auto_deref => 1,
    coerce     => 1,
);

has accessor => (
    isa => "Str",
    is  => "ro",
);

has accessor_args => (
    isa => "ArrayRef",
    is  => "ro",
    auto_deref => 1,
    coerce     => 1,
);

sub code {
    my $self = shift;

    my $obj = $self->class->new( $self->construct );
    my @accessor_args = $self->accessor_args;
    my $accessor = $self->accessor;

    sub { $obj->$accessor( @accessor_args ) };
}

__PACKAGE__;

__END__
