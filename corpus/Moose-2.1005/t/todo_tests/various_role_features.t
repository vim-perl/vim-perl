#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;

sub req_or_has ($$) {
    my ( $role, $method ) = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    if ( $role ) {
        ok(
            $role->has_method($method) || $role->requires_method($method),
            $role->name . " has or requires method $method"
        );
    } else {
        fail("role has or requires method $method");
    }
}

{
    package Bar;
    use Moose::Role;

    # this role eventually adds three methods, qw(foo bar xxy), but only one is
    # known when it's still a role

    has foo => ( is => "rw" );

    has gorch => ( reader => "bar" );

    sub xxy { "BAAAD" }

    package Gorch;
    use Moose::Role;

    # similarly this role gives attr and gorch_method

    has attr => ( is => "rw" );

    sub gorch_method { "gorch method" }

    around dandy => sub { shift->(@_) . "bar" };

    package Quxx;
    use Moose;

    sub dandy { "foo" }

    # this object will be used in an attr of Foo to test that Foo can do the
    # Gorch interface

    with qw(Gorch);

    package Dancer;
    use Moose::Role;

    requires "twist";

    package Dancer::Ballerina;
    use Moose;

    with qw(Dancer);

    sub twist { }

    sub pirouette { }

    package Dancer::Robot;
    use Moose::Role;

    # this doesn't fail but it produces a requires in the role
    # the order doesn't matter
    has twist => ( is => "rw" );
    ::is( ::exception { with qw(Dancer) }, undef );

    package Dancer::Something;
    use Moose;

    # this fail even though the method already exists

    has twist => ( is => "rw" );

    {
        ::is( ::exception { with qw(Dancer) }, undef );
    }

    package Dancer::80s;
    use Moose;

    # this should pass because ::Robot has the attribute to fill in the requires
    # but due to the deferrence logic that doesn't actually work
    {
        local our $TODO = "attribute accessor in role doesn't satisfy role requires";
        ::is( ::exception { with qw(Dancer::Robot) }, undef );
    }

    package Foo;
    use Moose;

    with qw(Bar);

    has oink => (
        is => "rw",
        handles => "Gorch", # should handles take the same arguments as 'with'? Meta::Role::Application::Delegation?
        default => sub { Quxx->new },
    );

    has dancer => (
        is => "rw",
        does => "Dancer",
        handles => "Dancer",
        default => sub { Dancer::Ballerina->new },
    );

    sub foo { 42 }

    sub bar { 33 }

    sub xxy { 7 }

    package Tree;
    use Moose::Role;

    has bark => ( is => "rw" );

    package Dog;
    use Moose::Role;

    sub bark { warn "woof!" };

    package EntPuppy;
    use Moose;

    {
        local our $TODO = "attrs and methods from a role should clash";
        ::isnt( ::exception { with qw(Tree Dog) }, undef );
    }
}

# these fail because of the deferral logic winning over actual methods
# this might be tricky to fix due to the 'sub foo {}; has foo => ( )' hack
# we've been doing for a long while, though I doubt people relied on it for
# anything other than fulfilling 'requires'
{
    local $TODO = "attributes from role overwrite class methods";
    is( Foo->new->foo, 42, "attr did not zap overriding method" );
    is( Foo->new->bar, 33, "attr did not zap overriding method" );
}
is( Foo->new->xxy, 7, "method did not zap overriding method" ); # duh

# these pass, simple delegate
# mostly they are here to contrast the next blck
can_ok( Foo->new->oink, "dandy" );
can_ok( Foo->new->oink, "attr" );
can_ok( Foo->new->oink, "gorch_method" );

ok( Foo->new->oink->does("Gorch"), "Quxx does Gorch" );


# these are broken because 'attr' is not technically part of the interface
can_ok( Foo->new, "gorch_method" );
{
    local $TODO = "accessor methods from a role are omitted in handles role";
    can_ok( Foo->new, "attr" );
}

{
    local $TODO = "handles role doesn't add the role to the ->does of the delegate's parent class";
    ok( Foo->new->does("Gorch"), "Foo does Gorch" );
}


# these work
can_ok( Foo->new->dancer, "pirouette" );
can_ok( Foo->new->dancer, "twist" );

can_ok( Foo->new, "twist" );
ok( !Foo->new->can("pirouette"), "can't pirouette, not part of the iface" );

{
    local $TODO = "handles role doesn't add the role to the ->does of the delegate's parent class";
    ok( Foo->new->does("Dancer") );
}




my $gorch = Gorch->meta;

isa_ok( $gorch, "Moose::Meta::Role" );

ok( $gorch->has_attribute("attr"), "has attribute 'attr'" );
isa_ok( $gorch->get_attribute("attr"), "Moose::Meta::Role::Attribute" );

req_or_has($gorch, "gorch_method");
ok( $gorch->has_method("gorch_method"), "has_method gorch_method" );
ok( !$gorch->requires_method("gorch_method"), "requires gorch method" );
isa_ok( $gorch->get_method("gorch_method"), "Moose::Meta::Method" );

{
    local $TODO = "method modifier doesn't yet create a method requirement or meta object";
    req_or_has($gorch, "dandy" );

    # this specific test is maybe not backwards compat, but in theory it *does*
    # require that method to exist
    ok( $gorch->requires_method("dandy"), "requires the dandy method for the modifier" );
}

{
    local $TODO = "attribute related methods are not yet known by the role";
    # we want this to be a part of the interface, somehow
    req_or_has($gorch, "attr");
    ok( $gorch->has_method("attr"), "has_method attr" );
    isa_ok( $gorch->get_method("attr"), "Moose::Meta::Method" );
    isa_ok( $gorch->get_method("attr"), "Moose::Meta::Method::Accessor" );
}

my $robot = Dancer::Robot->meta;

isa_ok( $robot, "Moose::Meta::Role" );

ok( $robot->has_attribute("twist"), "has attr 'twist'" );
isa_ok( $robot->get_attribute("twist"), "Moose::Meta::Role::Attribute" );

{
    req_or_has($robot, "twist");

    local $TODO = "attribute related methods are not yet known by the role";
    ok( $robot->has_method("twist"), "has twist method" );
    isa_ok( $robot->get_method("twist"), "Moose::Meta::Method" );
    isa_ok( $robot->get_method("twist"), "Moose::Meta::Method::Accessor" );
}

done_testing;

__END__

I think Attribute needs to be refactored in some way to better support roles.

There are several possible ways to do this, all of them seem plausible to me.

The first approach would be to change the attribute class to allow it to be
queried about the methods it would install.

Then we instantiate the attribute in the role, and instead of deferring the
arguments, we just make an C<unpack>ish method.

Then we can interrogate the attr when adding it to the role, and generate stub
methods for all the methods it would produce.

A second approach is kinda like the Immutable hack: wrap the attr in an
anonmyous class that disables part of its interface.

A third method would be to create an Attribute::Partial object that would
provide a more role-ish behavior, and to do this independently of the actual
Attribute class.

Something similar can be done for method modifiers, but I think that's even simpler.



The benefits of doing this are:

* Much better introspection of roles

* More correctness in many cases (in my opinion anyway)

* More roles are more usable as interface declarations, without having to split
  them into two pieces (one for the interface with a bunch of requires(), and
  another for the actual impl with the problematic attrs (and stub methods to
  fix the accessors) and method modifiers (dunno if this can even work at all)


