#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Moose::Util ':all';

{
  package Foo;

  use Moose::Role;
}

{
  package Bar;

  use Moose;

  with qw/Foo/;
}

{
  package Baz;

  use Moose;
}

{
  package Quux;

  use metaclass;
}

{
  package Foo::Foo;

  use Moose::Role;

  with 'Foo';
}

{
  package DoesMethod;
  use Moose;

  sub does {
    my $self = shift;
    my ($role) = @_;
    return 1 if $role eq 'Something::Else';
    return $self->SUPER::does(@_);
  }
}

# Classes

ok(does_role('Bar', 'Foo'), '... Bar does Foo');

ok(!does_role('Baz', 'Foo'), '... Baz doesnt do Foo');

# Objects

my $bar = Bar->new;

ok(does_role($bar, 'Foo'), '... $bar does Foo');

my $baz = Baz->new;

ok(!does_role($baz, 'Foo'), '... $baz doesnt do Foo');

# Invalid values

ok(!does_role(undef,'Foo'), '... undef doesnt do Foo');

ok(!does_role(1,'Foo'), '... 1 doesnt do Foo');

# non Moose metaclass

ok(!does_role('Quux', 'Foo'), '... Quux doesnt do Foo (does not die tho)');

# overriding the does method works properly

ok(does_role('DoesMethod', 'Something::Else'), '... can override the does method');

# Self

ok(does_role('Foo', 'Foo'), '... Foo does do Foo');

# sub-Roles

ok(does_role('Foo::Foo', 'Foo'), '... Foo::Foo does do Foo');

done_testing;
