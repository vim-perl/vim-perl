#!/usr/bin/perl

package Plain::Point;

use strict;
use warnings;

sub new {
    my ( $class, %params ) = @_;

    return bless {
        x => $params{x} || 10,
        y => $params{y},
    }, $class;
}

sub x {
    my ( $self, @args ) = @_;

    if ( @args ) {
        $self->{x} = $args[0];
    }

    return $self->{x};
}

sub y {
    my ( $self, @args ) = @_;

    if ( @args ) {
        $self->{y} = $args[0];
    }

    return $self->{y};
}

sub clear {
    my $self = shift;
    @{$self}{qw/x y/} = (0, 0);
}

__PACKAGE__;

__END__

