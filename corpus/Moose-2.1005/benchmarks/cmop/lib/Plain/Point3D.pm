#!/usr/bin/perl

package Plain::Point3D;

use strict;
use warnings;

use base 'Plain::Point';

sub new {
    my ( $class, %params ) = @_;
    my $self = $class->SUPER::new( %params );
    $self->{z} = $params{z};
    return $self;
}

sub z {
    my ( $self, @args ) = @_;

    if ( @args ) {
        $self->{z} = $args[0];
    }

    return $self->{z};
}

sub clear {
    my $self = shift;
    $self->SUPER::clear();
    $self->{z} = 0;
}

__PACKAGE__;

__END__

