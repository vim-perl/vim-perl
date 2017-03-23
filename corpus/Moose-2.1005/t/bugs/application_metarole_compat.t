#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::Fatal;

BEGIN {
    {
        package Foo;
        use Moose::Role;
    }

    {
        package Bar::Class;
        use Moose::Role;
    }

    {
        package Bar::ToClass;
        use Moose::Role;

        after apply => sub {
            my $self = shift;
            my ($role, $class) = @_;
            Moose::Util::MetaRole::apply_metaroles(
                for => $class,
                class_metaroles => {
                    class => ['Bar::Class'],
                }
            );
        };
    }

    {
        package Bar;
        use Moose::Role;
        Moose::Util::MetaRole::apply_metaroles(
            for => __PACKAGE__,
            role_metaroles => {
                application_to_class => ['Bar::ToClass'],
            }
        );
    }
}

{
    package Parent;
    use Moose -traits => 'Foo';
}

{
    package Child;
    use Moose -traits => 'Bar';
    ::is( ::exception { extends 'Parent' }, undef );
}

done_testing;
