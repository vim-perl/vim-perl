#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;


{
    package Foo;
    use Moose::Role;

    sub foo   { 'Foo::foo'   }
    sub bar   { 'Foo::bar'   }
    sub baz   { 'Foo::baz'   }
    sub gorch { 'Foo::gorch' }

    package Bar;
    use Moose::Role;

    sub foo   { 'Bar::foo'   }
    sub bar   { 'Bar::bar'   }
    sub baz   { 'Bar::baz'   }
    sub gorch { 'Bar::gorch' }

    package Baz;
    use Moose::Role;

    sub foo   { 'Baz::foo'   }
    sub bar   { 'Baz::bar'   }
    sub baz   { 'Baz::baz'   }
    sub gorch { 'Baz::gorch' }

    package Gorch;
    use Moose::Role;

    sub foo   { 'Gorch::foo'   }
    sub bar   { 'Gorch::bar'   }
    sub baz   { 'Gorch::baz'   }
    sub gorch { 'Gorch::gorch' }
}

{
    package My::Class;
    use Moose;

    ::is( ::exception {
        with 'Foo'   => { -excludes => [qw/bar baz gorch/], -alias => { gorch => 'foo_gorch' } },
             'Bar'   => { -excludes => [qw/foo baz gorch/] },
             'Baz'   => { -excludes => [qw/foo bar gorch/], -alias => { foo => 'baz_foo', bar => 'baz_bar' } },
             'Gorch' => { -excludes => [qw/foo bar baz/] };
    }, undef, '... everything works out all right' );
}

my $c = My::Class->new;
isa_ok($c, 'My::Class');

is($c->foo, 'Foo::foo', '... got the right method');
is($c->bar, 'Bar::bar', '... got the right method');
is($c->baz, 'Baz::baz', '... got the right method');
is($c->gorch, 'Gorch::gorch', '... got the right method');

is($c->foo_gorch, 'Foo::gorch', '... got the right method');
is($c->baz_foo, 'Baz::foo', '... got the right method');
is($c->baz_bar, 'Baz::bar', '... got the right method');

{
    package Splunk;

    use Moose::Role;

    sub baz   { 'Splunk::baz'   }
    sub gorch { 'Splunk::gorch' }

    ::is(::exception { with 'Foo' }, undef, 'role to role application works');

    package My::Class2;

    use Moose;

    ::is(::exception { with 'Splunk' }, undef, 'and the role can be consumed');
}

is(My::Class2->foo, 'Foo::foo', '... got the right method');
is(My::Class2->bar, 'Foo::bar', '... got the right method');
is(My::Class2->baz, 'Splunk::baz', '... got the right method');
is(My::Class2->gorch, 'Splunk::gorch', '... got the right method');

done_testing;
