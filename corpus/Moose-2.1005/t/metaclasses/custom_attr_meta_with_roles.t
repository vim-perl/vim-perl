#!/usr/bin/perl

use strict;
use warnings;

use Test::More;


{
    package My::Custom::Meta::Attr;
    use Moose;

    extends 'Moose::Meta::Attribute';
}

{
    package My::Fancy::Role;
    use Moose::Role;

    has 'bling_bling' => (
        metaclass => 'My::Custom::Meta::Attr',
        is        => 'rw',
        isa       => 'Str',
    );
}

{
    package My::Class;
    use Moose;

    with 'My::Fancy::Role';
}

my $c = My::Class->new;
isa_ok($c, 'My::Class');

ok($c->meta->has_attribute('bling_bling'), '... got the attribute');

isa_ok($c->meta->get_attribute('bling_bling'), 'My::Custom::Meta::Attr');

done_testing;
