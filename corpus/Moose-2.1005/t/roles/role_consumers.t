use strict;
use warnings;

use Test::More;

{
    package Foo::Role;
    use Moose::Role;
}

{
    package Bar::Role;
    use Moose::Role;
}

{
    package Foo;
    use Moose;
    with 'Foo::Role';
}

{
    package Bar;
    use Moose;
    extends 'Foo';
    with 'Bar::Role';
}

{
    package FooBar;
    use Moose;
    with 'Foo::Role', 'Bar::Role';
}

{
    package Foo::Role::User;
    use Moose::Role;
    with 'Foo::Role';
}

{
    package Foo::User;
    use Moose;
    with 'Foo::Role::User';
}

is_deeply([sort Foo::Role->meta->consumers],
          ['Bar', 'Foo', 'Foo::Role::User', 'Foo::User', 'FooBar']);
is_deeply([sort Bar::Role->meta->consumers],
          ['Bar', 'FooBar']);
is_deeply([sort Foo::Role::User->meta->consumers],
          ['Foo::User']);

done_testing;
