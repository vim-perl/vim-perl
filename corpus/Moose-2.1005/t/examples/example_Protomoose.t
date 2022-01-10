#!/usr/local/bin/perl

use strict;
use warnings;

use Test::More;

=pod

This is an example of making Moose behave
more like a prototype based object system.

Why?

Well cause merlyn asked if it could :)

=cut

## ------------------------------------------------------------------
## make some metaclasses

{
    package ProtoMoose::Meta::Instance;
    use Moose;

    BEGIN { extends 'Moose::Meta::Instance' };

    # NOTE:
    # do not let things be inlined by
    # the attribute or accessor generator
    sub is_inlinable { 0 }
}

{
    package ProtoMoose::Meta::Method::Accessor;
    use Moose;

    BEGIN { extends 'Moose::Meta::Method::Accessor' };

    # customize the accessors to always grab
    # the correct instance in the accessors

    sub find_instance {
        my ($self, $candidate, $accessor_type) = @_;

        my $instance = $candidate;
        my $attr     = $self->associated_attribute;

        # if it is a class calling it ...
        unless (blessed($instance)) {
            # then grab the class prototype
            $instance = $attr->associated_class->prototype_instance;
        }
        # if its an instance ...
        else {
            # and there is no value currently
            # associated with the instance and
            # we are trying to read it, then ...
            if ($accessor_type eq 'r' && !defined($attr->get_value($instance))) {
                # again, defer the prototype in
                # the class in which is was defined
                $instance = $attr->associated_class->prototype_instance;
            }
            # otherwise, you want to assign
            # to your local copy ...
        }
        return $instance;
    }

    sub _generate_accessor_method {
        my $self = shift;
        my $attr = $self->associated_attribute;
        return sub {
            if (scalar(@_) == 2) {
                $attr->set_value(
                    $self->find_instance($_[0], 'w'),
                    $_[1]
                );
            }
            $attr->get_value($self->find_instance($_[0], 'r'));
        };
    }

    sub _generate_reader_method {
        my $self = shift;
        my $attr = $self->associated_attribute;
        return sub {
            confess "Cannot assign a value to a read-only accessor" if @_ > 1;
            $attr->get_value($self->find_instance($_[0], 'r'));
        };
    }

    sub _generate_writer_method {
        my $self = shift;
        my $attr = $self->associated_attribute;
        return sub {
            $attr->set_value(
                $self->find_instance($_[0], 'w'),
                $_[1]
            );
        };
    }

    # deal with these later ...
    sub generate_predicate_method {}
    sub generate_clearer_method {}

}

{
    package ProtoMoose::Meta::Attribute;
    use Moose;

    BEGIN { extends 'Moose::Meta::Attribute' };

    sub accessor_metaclass { 'ProtoMoose::Meta::Method::Accessor' }
}

{
    package ProtoMoose::Meta::Class;
    use Moose;

    BEGIN { extends 'Moose::Meta::Class' };

    has 'prototype_instance' => (
        is        => 'rw',
        isa       => 'Object',
        predicate => 'has_prototypical_instance',
        lazy      => 1,
        default   => sub { (shift)->new_object }
    );

    sub initialize {
        # NOTE:
        # I am not sure why 'around' does
        # not work here, have to investigate
        # it later - SL
        (shift)->SUPER::initialize(@_,
            instance_metaclass  => 'ProtoMoose::Meta::Instance',
            attribute_metaclass => 'ProtoMoose::Meta::Attribute',
        );
    }

    around '_construct_instance' => sub {
        my $next = shift;
        my $self = shift;
        # NOTE:
        # we actually have to do this here
        # to tie-the-knot, if you take it
        # out, then you get deep recursion
        # several levels deep :)
        $self->prototype_instance($next->($self, @_))
            unless $self->has_prototypical_instance;
        return $self->prototype_instance;
    };

}

{
    package ProtoMoose::Object;
    use metaclass 'ProtoMoose::Meta::Class';
    use Moose;

    sub new {
        my $prototype = blessed($_[0])
            ? $_[0]
            : $_[0]->meta->prototype_instance;
        my (undef, %params) = @_;
        my $self = $prototype->meta->clone_object($prototype, %params);
        $self->BUILDALL(\%params);
        return $self;
    }
}

## ------------------------------------------------------------------
## make some classes now

{
    package Foo;
    use Moose;

    extends 'ProtoMoose::Object';

    has 'bar' => (is => 'rw');
}

{
    package Bar;
    use Moose;

    extends 'Foo';

    has 'baz' => (is => 'rw');
}

## ------------------------------------------------------------------

## ------------------------------------------------------------------
## Check that metaclasses are working/inheriting properly

foreach my $class (qw/ProtoMoose::Object Foo Bar/) {
    isa_ok($class->meta,
    'ProtoMoose::Meta::Class',
    '... got the right metaclass for ' . $class . ' ->');

    is($class->meta->instance_metaclass,
    'ProtoMoose::Meta::Instance',
    '... got the right instance meta for ' . $class);

    is($class->meta->attribute_metaclass,
    'ProtoMoose::Meta::Attribute',
    '... got the right attribute meta for ' . $class);
}

## ------------------------------------------------------------------

# get the prototype for Foo
my $foo_prototype = Foo->meta->prototype_instance;
isa_ok($foo_prototype, 'Foo');

# set a value in the prototype
$foo_prototype->bar(100);
is($foo_prototype->bar, 100, '... got the value stored in the prototype');

# the "class" defers to the
# the prototype when asked
# about attributes
is(Foo->bar, 100, '... got the value stored in the prototype (through the Foo class)');

# now make an instance, which
# is basically a clone of the
# prototype
my $foo = Foo->new;
isa_ok($foo, 'Foo');

# the instance is *not* the prototype
isnt($foo, $foo_prototype, '... got a new instance of Foo');

# but it has the same values ...
is($foo->bar, 100, '... got the value stored in the instance (inherited from the prototype)');

# we can even change the values
# in the instance
$foo->bar(300);
is($foo->bar, 300, '... got the value stored in the instance (overwriting the one inherited from the prototype)');

# and not change the one in the prototype
is($foo_prototype->bar, 100, '... got the value stored in the prototype');
is(Foo->bar, 100, '... got the value stored in the prototype (through the Foo class)');

## subclasses

# now we can check that the subclass
# will seek out the correct prototypical
# value from its "parent"
is(Bar->bar, 100, '... got the value stored in the Foo prototype (through the Bar class)');

# we can then also set its local attrs
Bar->baz(50);
is(Bar->baz, 50, '... got the value stored in the prototype (through the Bar class)');

# now we clone the Bar prototype
my $bar = Bar->new;
isa_ok($bar, 'Bar');
isa_ok($bar, 'Foo');

# and we see that we got the right values
# in the instance/clone
is($bar->bar, 100, '... got the value stored in the instance (inherited from the Foo prototype)');
is($bar->baz, 50, '... got the value stored in the instance (inherited from the Bar prototype)');

# nowe we can change the value
$bar->bar(200);
is($bar->bar, 200, '... got the value stored in the instance (overriding the one inherited from the Foo prototype)');

# and all our original and
# prototypical values are still
# the same
is($foo->bar, 300, '... still got the original value stored in the instance (inherited from the prototype)');
is(Foo->bar, 100, '... still got the original value stored in the prototype (through the Foo class)');
is(Bar->bar, 100, '... still got the original value stored in the prototype (through the Bar class)');

done_testing;
