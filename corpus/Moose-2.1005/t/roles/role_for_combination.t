#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

my $OPTS;
do {
    package My::Singleton::Role;
    use Moose::Role;

    sub foo { 'My::Singleton::Role' }

    package My::Role::Metaclass;
    use Moose;
    BEGIN { extends 'Moose::Meta::Role' };

    sub _role_for_combination {
        my ($self, $opts) = @_;
        $OPTS = $opts;
        return My::Singleton::Role->meta;
    }

    package My::Special::Role;
    use Moose::Role -metaclass => 'My::Role::Metaclass';

    sub foo { 'My::Special::Role' }

    package My::Usual::Role;
    use Moose::Role;

    sub bar { 'My::Usual::Role' }

    package My::Class;
    use Moose;

    with (
        'My::Special::Role' => { number => 1 },
        'My::Usual::Role' => { number => 2 },
    );
};

is(My::Class->foo, 'My::Singleton::Role', 'role_for_combination applied');
is(My::Class->bar, 'My::Usual::Role', 'collateral role');
is_deeply($OPTS, { number => 1 });

done_testing;
