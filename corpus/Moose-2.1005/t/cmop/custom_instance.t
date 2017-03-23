#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::Fatal;

use Class::MOP;

my $instance;
{
    package Foo;

    sub new {
        my $class = shift;
        $instance = bless {@_}, $class;
        return $instance;
    }

    sub foo { shift->{foo} }
}

{
    package Foo::Sub;
    use base 'Foo';
    use metaclass;

    sub new {
        my $class = shift;
        $class->meta->new_object(
            __INSTANCE__ => $class->SUPER::new(@_),
            @_,
        );
    }

    __PACKAGE__->meta->add_attribute(
        bar => (
            reader      => 'bar',
            initializer => sub {
                my $self = shift;
                my ($value, $writer, $attr) = @_;
                $writer->(uc $value);
            },
        ),
    );
}

undef $instance;
is( exception {
    my $foo = Foo::Sub->new;
    isa_ok($foo, 'Foo');
    isa_ok($foo, 'Foo::Sub');
    is($foo, $instance, "used the passed-in instance");
}, undef );

undef $instance;
is( exception {
    my $foo = Foo::Sub->new(foo => 'FOO');
    isa_ok($foo, 'Foo');
    isa_ok($foo, 'Foo::Sub');
    is($foo, $instance, "used the passed-in instance");
    is($foo->foo, 'FOO', "set non-CMOP constructor args");
}, undef );

undef $instance;
is( exception {
    my $foo = Foo::Sub->new(bar => 'bar');
    isa_ok($foo, 'Foo');
    isa_ok($foo, 'Foo::Sub');
    is($foo, $instance, "used the passed-in instance");
    is($foo->bar, 'BAR', "set CMOP attributes");
}, undef );

undef $instance;
is( exception {
    my $foo = Foo::Sub->new(foo => 'FOO', bar => 'bar');
    isa_ok($foo, 'Foo');
    isa_ok($foo, 'Foo::Sub');
    is($foo, $instance, "used the passed-in instance");
    is($foo->foo, 'FOO', "set non-CMOP constructor arg");
    is($foo->bar, 'BAR', "set correct CMOP attribute");
}, undef );

{
    package BadFoo;

    sub new {
        my $class = shift;
        $instance = bless {@_};
        return $instance;
    }

    sub foo { shift->{foo} }
}

{
    package BadFoo::Sub;
    use base 'BadFoo';
    use metaclass;

    sub new {
        my $class = shift;
        $class->meta->new_object(
            __INSTANCE__ => $class->SUPER::new(@_),
            @_,
        );
    }

    __PACKAGE__->meta->add_attribute(
        bar => (
            reader      => 'bar',
            initializer => sub {
                my $self = shift;
                my ($value, $writer, $attr) = @_;
                $writer->(uc $value);
            },
        ),
    );
}

like( exception { BadFoo::Sub->new }, qr/BadFoo=HASH.*is not a BadFoo::Sub/, "error with incorrect constructors" );

{
    my $meta = Class::MOP::Class->create('Really::Bad::Foo');
    like( exception {
        $meta->new_object(__INSTANCE__ => (bless {}, 'Some::Other::Class'))
    }, qr/Some::Other::Class=HASH.*is not a Really::Bad::Foo/, "error with completely invalid class" );
}

{
    my $meta = Class::MOP::Class->create('Really::Bad::Foo::2');
    for my $invalid ('foo', 1, 0, '') {
        like( exception {
            $meta->new_object(__INSTANCE__ => $invalid)
        }, qr/The __INSTANCE__ parameter must be a blessed reference, not $invalid/, "error with unblessed thing" );
    }
}

done_testing;
