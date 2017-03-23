#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;

{
    package Foo;

    sub new {
        bless({}, 'Foo')
    }

    sub a { 'Foo::a' }
}

{
    package Bar;
    use Moose;

    ::is( ::exception {
        has 'baz' => (
            is      => 'ro',
            isa     => 'Foo',
            lazy    => 1,
            default => sub { Foo->new() },
            handles => qr/^a$/,
        );
    }, undef, '... can create the attribute with delegations' );

}

my $bar;
is( exception {
    $bar = Bar->new;
}, undef, '... created the object ok' );
isa_ok($bar, 'Bar');

is($bar->a, 'Foo::a', '... got the right delgated value');

my @w;
$SIG{__WARN__} = sub { push @w, "@_" };
{
    package Baz;
    use Moose;

    ::is( ::exception {
        has 'bar' => (
            is      => 'ro',
            isa     => 'Foo',
            lazy    => 1,
            default => sub { Foo->new() },
            handles => qr/.*/,
        );
    }, undef, '... can create the attribute with delegations' );

}

is(@w, 0, "no warnings");


my $baz;
is( exception {
    $baz = Baz->new;
}, undef, '... created the object ok' );
isa_ok($baz, 'Baz');

is($baz->a, 'Foo::a', '... got the right delgated value');





@w = ();

{
    package Blart;
    use Moose;

    ::is( ::exception {
        has 'bar' => (
            is      => 'ro',
            isa     => 'Foo',
            lazy    => 1,
            default => sub { Foo->new() },
            handles => [qw(a new)],
        );
    }, undef, '... can create the attribute with delegations' );

}

{
    local $TODO = "warning not yet implemented";

    is(@w, 1, "one warning");
    like($w[0], qr/not delegating.*new/i, "warned");
}



my $blart;
is( exception {
    $blart = Blart->new;
}, undef, '... created the object ok' );
isa_ok($blart, 'Blart');

is($blart->a, 'Foo::a', '... got the right delgated value');

done_testing;
