#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

{
    # so we don't pick up stuff from Moose::Object
    package Base;
    sub foo { } # touch it so that 'extends' doesn't try to load it
}

{
    package Foo;
    use Moose;
    extends 'Base';
    no Moose;
}
can_ok('Foo', 'meta');
is(Foo->meta, Class::MOP::class_of('Foo'));
isa_ok(Foo->meta->get_method('meta'), 'Moose::Meta::Method::Meta');

{
    package Bar;
    use Moose -meta_name => 'bar_meta';
    extends 'Base';
    no Moose;
}
ok(!Bar->can('meta'));
can_ok('Bar', 'bar_meta');
is(Bar->bar_meta, Class::MOP::class_of('Bar'));
isa_ok(Bar->bar_meta->get_method('bar_meta'), 'Moose::Meta::Method::Meta');

{
    package Baz;
    use Moose -meta_name => undef;
    extends 'Base';
    no Moose;
}
ok(!Baz->can('meta'));

my $universal_method_count = scalar Class::MOP::class_of('UNIVERSAL')->get_all_methods;
# 1 because of the dummy method we installed in Base
is( ( scalar Class::MOP::class_of('Baz')->get_all_methods )
    - $universal_method_count, 1 );

done_testing;
