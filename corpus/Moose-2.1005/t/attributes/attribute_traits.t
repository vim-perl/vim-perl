#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Moose;


{
    package My::Attribute::Trait;
    use Moose::Role;

    has 'alias_to' => (is => 'ro', isa => 'Str');

    has foo => ( is => "ro", default => "blah" );

    after 'install_accessors' => sub {
        my $self = shift;
        $self->associated_class->add_method(
            $self->alias_to,
            $self->get_read_method_ref
        );
    };
}

{
    package My::Class;
    use Moose;

    has 'bar' => (
        traits   => [qw/My::Attribute::Trait/],
        is       => 'ro',
        isa      => 'Int',
        alias_to => 'baz',
    );

    has 'gorch' => (
        is      => 'ro',
        isa     => 'Int',
        default => sub { 10 }
    );
}

my $c = My::Class->new(bar => 100);
isa_ok($c, 'My::Class');

is($c->bar, 100, '... got the right value for bar');
is($c->gorch, 10, '... got the right value for gorch');

can_ok($c, 'baz');
is($c->baz, 100, '... got the right value for baz');

my $bar_attr = $c->meta->get_attribute('bar');
does_ok($bar_attr, 'My::Attribute::Trait');
ok($bar_attr->has_applied_traits, '... got the applied traits');
is_deeply($bar_attr->applied_traits, [qw/My::Attribute::Trait/], '... got the applied traits');
is($bar_attr->foo, "blah", "attr initialized");

my $gorch_attr = $c->meta->get_attribute('gorch');
ok(!$gorch_attr->does('My::Attribute::Trait'), '... gorch doesnt do the trait');
ok(!$gorch_attr->has_applied_traits, '... no traits applied');
is($gorch_attr->applied_traits, undef, '... no traits applied');

done_testing;
