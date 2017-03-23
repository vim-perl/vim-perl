#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

{
    package Foo::Role;
    use Moose::Role;
}

{
    package Foo;
    use Moose;

    with 'Foo::Role';
}

{
    package Foo::Sub;
    use base 'Foo';
}

{
    package Foo::Sub2;
    use base 'Foo';
}

{
    package Foo::Sub3;
    use base 'Foo';
}

{
    package Foo::Sub4;
    use base 'Foo';
}

ok(Foo::Sub->does('Foo::Role'), "class does Foo::Role");
ok(Foo::Sub2->new->does('Foo::Role'), "object does Foo::Role");
ok(!Foo::Sub3->does('Bar::Role'), "class doesn't do Bar::Role");
ok(!Foo::Sub4->new->does('Bar::Role'), "object doesn't do Bar::Role");

done_testing;
