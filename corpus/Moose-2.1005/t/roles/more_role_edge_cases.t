#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;


{
    # NOTE:
    # this tests that repeated role
    # composition will not cause
    # a conflict between two methods
    # which are actually the same anyway

    {
        package RootA;
        use Moose::Role;

        sub foo { "RootA::foo" }

        package SubAA;
        use Moose::Role;

        with "RootA";

        sub bar { "SubAA::bar" }

        package SubAB;
        use Moose;

        ::is( ::exception {
            with "SubAA", "RootA";
        }, undef, '... role was composed as expected' );
    }

    ok( SubAB->does("SubAA"), "does SubAA");
    ok( SubAB->does("RootA"), "does RootA");

    isa_ok( my $i = SubAB->new, "SubAB" );

    can_ok( $i, "bar" );
    is( $i->bar, "SubAA::bar", "... got thr right bar rv" );

    can_ok( $i, "foo" );
    my $foo_rv;
    is( exception {
        $foo_rv = $i->foo;
    }, undef, '... called foo successfully' );
    is($foo_rv, "RootA::foo", "... got the right foo rv");
}

{
    # NOTE:
    # this edge cases shows the application of
    # an after modifier over a method which
    # was added during role composotion.
    # The way this will work is as follows:
    #    role SubBA will consume RootB and
    #    get a local copy of RootB::foo, it
    #    will also store a deferred after modifier
    #    to be applied to whatever class SubBA is
    #    composed into.
    #    When class SubBB comsumed role SubBA, the
    #    RootB::foo method is added to SubBB, then
    #    the deferred after modifier from SubBA is
    #    applied to it.
    # It is important to note that the application
    # of the after modifier does not happen until
    # role SubBA is composed into SubAA.

    {
        package RootB;
        use Moose::Role;

        sub foo { "RootB::foo" }

        package SubBA;
        use Moose::Role;

        with "RootB";

        has counter => (
            isa => "Num",
            is  => "rw",
            default => 0,
        );

        after foo => sub {
            $_[0]->counter( $_[0]->counter + 1 );
        };

        package SubBB;
        use Moose;

        ::is( ::exception {
            with "SubBA";
        }, undef, '... composed the role successfully' );
    }

    ok( SubBB->does("SubBA"), "BB does SubBA" );
    ok( SubBB->does("RootB"), "BB does RootB" );

    isa_ok( my $i = SubBB->new, "SubBB" );

    can_ok( $i, "foo" );

    my $foo_rv;
    is( exception {
        $foo_rv = $i->foo
    }, undef, '... called foo successfully' );
    is( $foo_rv, "RootB::foo", "foo rv" );
    is( $i->counter, 1, "after hook called" );

    is( exception { $i->foo }, undef, '... called foo successfully (again)' );
    is( $i->counter, 2, "after hook called (again)" );

    ok(SubBA->meta->has_method('foo'), '... this has the foo method');
    #my $subba_foo_rv;
    #lives_ok {
    #    $subba_foo_rv = SubBA::foo();
    #} '... called the sub as a function correctly';
    #is($subba_foo_rv, 'RootB::foo', '... the SubBA->foo is still the RootB version');
}

{
    # NOTE:
    # this checks that an override method
    # does not try to trample over a locally
    # composed in method. In this case the
    # RootC::foo, which is composed into
    # SubCA cannot be trampled with an
    # override of 'foo'
    {
        package RootC;
        use Moose::Role;

        sub foo { "RootC::foo" }

        package SubCA;
        use Moose::Role;

        with "RootC";

        ::isnt( ::exception {
            override foo => sub { "overridden" };
        }, undef, '... cannot compose an override over a local method' );
    }
}

# NOTE:
# need to talk to Yuval about the motivation behind
# this test, I am not sure we are testing anything
# useful here (although more tests cant hurt)

{
    use List::Util qw/shuffle/;

    {
        package Abstract;
        use Moose::Role;

        requires "method";
        requires "other";

        sub another { "abstract" }

        package ConcreteA;
        use Moose::Role;
        with "Abstract";

        sub other { "concrete a" }

        package ConcreteB;
        use Moose::Role;
        with "Abstract";

        sub method { "concrete b" }

        package ConcreteC;
        use Moose::Role;
        with "ConcreteA";

        # NOTE:
        # this was originally override, but
        # that wont work (see above set of tests)
        # so I switched it to around.
        # However, this may not be testing the
        # same thing that was originally intended
        around other => sub {
            return ( (shift)->() . " + c" );
        };

        package SimpleClassWithSome;
        use Moose;

        eval { with ::shuffle qw/ConcreteA ConcreteB/ };
        ::ok( !$@, "simple composition without abstract" ) || ::diag $@;

        package SimpleClassWithAll;
        use Moose;

        eval { with ::shuffle qw/ConcreteA ConcreteB Abstract/ };
        ::ok( !$@, "simple composition with abstract" ) || ::diag $@;
    }

    foreach my $class (qw/SimpleClassWithSome SimpleClassWithAll/) {
        foreach my $role (qw/Abstract ConcreteA ConcreteB/) {
            ok( $class->does($role), "$class does $role");
        }

        foreach my $method (qw/method other another/) {
            can_ok( $class, $method );
        }

        is( eval { $class->another }, "abstract", "provided by abstract" );
        is( eval { $class->other }, "concrete a", "provided by concrete a" );
        is( eval { $class->method }, "concrete b", "provided by concrete b" );
    }

    {
        package ClassWithSome;
        use Moose;

        eval { with ::shuffle qw/ConcreteC ConcreteB/ };
        ::ok( !$@, "composition without abstract" ) || ::diag $@;

        package ClassWithAll;
        use Moose;

        eval { with ::shuffle qw/ConcreteC Abstract ConcreteB/ };
        ::ok( !$@, "composition with abstract" ) || ::diag $@;

        package ClassWithEverything;
        use Moose;

        eval { with ::shuffle qw/ConcreteC Abstract ConcreteA ConcreteB/ }; # this should clash
        ::ok( !$@, "can compose ConcreteA and ConcreteC together" );
    }

    foreach my $class (qw/ClassWithSome ClassWithAll ClassWithEverything/) {
        foreach my $role (qw/Abstract ConcreteA ConcreteB ConcreteC/) {
            ok( $class->does($role), "$class does $role");
        }

        foreach my $method (qw/method other another/) {
            can_ok( $class, $method );
        }

        is( eval { $class->another }, "abstract", "provided by abstract" );
        is( eval { $class->other }, "concrete a + c", "provided by concrete c + a" );
        is( eval { $class->method }, "concrete b", "provided by concrete b" );
    }
}

done_testing;
