#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;


{

    package Foo::Role;
    use Moose::Role;

    requires 'foo';
}

is_deeply(
    [ sort Foo::Role->meta->get_required_method_list ],
    ['foo'],
    '... the Foo::Role has a required method (foo)'
);

# classes which does not implement required method
{

    package Foo::Class;
    use Moose;

    ::isnt( ::exception { with('Foo::Role') }, undef, '... no foo method implemented by Foo::Class' );
}

# class which does implement required method
{

    package Bar::Class;
    use Moose;

    ::isnt( ::exception { with('Foo::Class') }, undef, '... cannot consume a class, it must be a role' );
    ::is( ::exception { with('Foo::Role') }, undef, '... has a foo method implemented by Bar::Class' );

    sub foo {'Bar::Class::foo'}
}

# role which does implement required method
{

    package Bar::Role;
    use Moose::Role;

    ::is( ::exception { with('Foo::Role') }, undef, '... has a foo method implemented by Bar::Role' );

    sub foo {'Bar::Role::foo'}
}

is_deeply(
    [ sort Bar::Role->meta->get_required_method_list ],
    [],
    '... the Bar::Role has not inherited the required method from Foo::Role'
);

# role which does not implement required method
{

    package Baz::Role;
    use Moose::Role;

    ::is( ::exception { with('Foo::Role') }, undef, '... no foo method implemented by Baz::Role' );
}

is_deeply(
    [ sort Baz::Role->meta->get_required_method_list ],
    ['foo'],
    '... the Baz::Role has inherited the required method from Foo::Role'
);

# classes which does not implement required method
{

    package Baz::Class;
    use Moose;

    ::isnt( ::exception { with('Baz::Role') }, undef, '... no foo method implemented by Baz::Class2' );
}

# class which does implement required method
{

    package Baz::Class2;
    use Moose;

    ::is( ::exception { with('Baz::Role') }, undef, '... has a foo method implemented by Baz::Class2' );

    sub foo {'Baz::Class2::foo'}
}


{
    package Quux::Role;
    use Moose::Role;

    requires qw( meth1 meth2 meth3 meth4 );
}

# RT #41119
{

    package Quux::Class;
    use Moose;

    ::like( ::exception { with('Quux::Role') }, qr/\Q'Quux::Role' requires the methods 'meth1', 'meth2', 'meth3', and 'meth4' to be implemented by 'Quux::Class'/, 'exception mentions all the missing required methods at once' );
}

{
    package Quux::Class2;
    use Moose;

    sub meth1 { }

    ::like( ::exception { with('Quux::Role') }, qr/'Quux::Role' requires the methods 'meth2', 'meth3', and 'meth4' to be implemented by 'Quux::Class2'/, 'exception mentions all the missing required methods at once, but not the one that exists' );
}

{
    package Quux::Class3;
    use Moose;

    has 'meth1' => ( is => 'ro' );
    has 'meth2' => ( is => 'ro' );

    ::like( ::exception { with('Quux::Role') }, qr/'Quux::Role' requires the methods 'meth3' and 'meth4' to be implemented by 'Quux::Class3'/, 'exception mentions all the missing methods at once, but not the accessors' );
}

{
    package Quux::Class4;
    use Moose;

    sub meth1 { }
    has 'meth2' => ( is => 'ro' );

    ::like( ::exception { with('Quux::Role') }, qr/'Quux::Role' requires the methods 'meth3' and 'meth4' to be implemented by 'Quux::Class4'/, 'exception mentions all the require methods that are accessors at once, as well as missing methods, but not the one that exists' );
}

done_testing;
