#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

my ($super_called, $sub_called, $new_super_called) = (0, 0, 0);
{
    package Foo;
    use Moose;

    sub foo { $super_called++ }
}

{
    package Foo::Sub;
    use Moose;
    extends 'Foo';

    override foo => sub {
        $sub_called++;
        super();
    };
}

Foo::Sub->new->foo;
is($super_called, 1, "super called");
is($new_super_called, 0, "new super not called");
is($sub_called, 1, "sub called");

($super_called, $sub_called, $new_super_called) = (0, 0, 0);

Foo->meta->add_method(foo => sub {
    $new_super_called++;
});

Foo::Sub->new->foo;
{ local $TODO = "super doesn't get replaced";
is($super_called, 0, "super not called");
is($new_super_called, 1, "new super called");
}
is($sub_called, 1, "sub called");

done_testing;
