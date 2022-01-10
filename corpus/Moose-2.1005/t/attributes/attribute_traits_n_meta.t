#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Moose;



{
    package My::Meta::Attribute::DefaultReadOnly;
    use Moose;

    extends 'Moose::Meta::Attribute';

    around 'new' => sub {
        my $next = shift;
        my ($self, $name, %options) = @_;
        $options{is} = 'ro'
            unless exists $options{is};
        $next->($self, $name, %options);
    };
}

{
    package My::Attribute::Trait;
    use Moose::Role;

    has 'alias_to' => (is => 'ro', isa => 'Str');

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
        metaclass => 'My::Meta::Attribute::DefaultReadOnly',
        traits    => [qw/My::Attribute::Trait/],
        isa       => 'Int',
        alias_to  => 'baz',
    );
}

my $c = My::Class->new(bar => 100);
isa_ok($c, 'My::Class');

is($c->bar, 100, '... got the right value for bar');

can_ok($c, 'baz');
is($c->baz, 100, '... got the right value for baz');

isa_ok($c->meta->get_attribute('bar'), 'My::Meta::Attribute::DefaultReadOnly');
does_ok($c->meta->get_attribute('bar'), 'My::Attribute::Trait');
is($c->meta->get_attribute('bar')->_is_metadata, 'ro', '... got the right metaclass customization');

done_testing;
