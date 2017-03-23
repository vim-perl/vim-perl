#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;

=pod

This tests the more complex
delegation cases and that they
do not fail at compile time.

=cut

{

    package ChildASuper;
    use Moose;

    sub child_a_super_method { "as" }

    package ChildA;
    use Moose;

    extends "ChildASuper";

    sub child_a_method_1 { "a1" }
    sub child_a_method_2 { Scalar::Util::blessed($_[0]) . " a2" }

    package ChildASub;
    use Moose;

    extends "ChildA";

    sub child_a_method_3 { "a3" }

    package ChildB;
    use Moose;

    sub child_b_method_1 { "b1" }
    sub child_b_method_2 { "b2" }
    sub child_b_method_3 { "b3" }

    package ChildC;
    use Moose;

    sub child_c_method_1 { "c1" }
    sub child_c_method_2 { "c2" }
    sub child_c_method_3_la { "c3" }
    sub child_c_method_4_la { "c4" }

    package ChildD;
    use Moose;

    sub child_d_method_1 { "d1" }
    sub child_d_method_2 { "d2" }

    package ChildE;
    # no Moose

    sub new { bless {}, shift }
    sub child_e_method_1 { "e1" }
    sub child_e_method_2 { "e2" }

    package ChildF;
    # no Moose

    sub new { bless {}, shift }
    sub child_f_method_1 { "f1" }
    sub child_f_method_2 { "f2" }

    package ChildG;
    use Moose;

    sub child_g_method_1 { "g1" }

    package ChildH;
    use Moose;

    sub child_h_method_1 { "h1" }
    sub parent_method_1 { "child_parent_1" }

    package ChildI;
    use Moose;

    sub child_i_method_1 { "i1" }
    sub parent_method_1 { "child_parent_1" }

    package Parent;
    use Moose;

    sub parent_method_1 { "parent_1" }
    ::can_ok('Parent', 'parent_method_1');

    ::isnt( ::exception {
        has child_a => (
            is      => "ro",
            default => sub { ChildA->new },
            handles => qr/.*/,
        );
    }, undef, "all_methods requires explicit isa" );

    ::is( ::exception {
        has child_a => (
            isa     => "ChildA",
            is      => "ro",
            default => sub { ChildA->new },
            handles => qr/.*/,
        );
    }, undef, "allow all_methods with explicit isa" );

    ::is( ::exception {
        has child_b => (
            is      => 'ro',
            default => sub { ChildB->new },
            handles => [qw/child_b_method_1/],
        );
    }, undef, "don't need to declare isa if method list is predefined" );

    ::is( ::exception {
        has child_c => (
            isa     => "ChildC",
            is      => "ro",
            default => sub { ChildC->new },
            handles => qr/_la$/,
        );
    }, undef, "can declare regex collector" );

    ::isnt( ::exception {
        has child_d => (
            is      => "ro",
            default => sub { ChildD->new },
            handles => sub {
                my ( $class, $delegate_class ) = @_;
            }
        );
    }, undef, "can't create attr with generative handles parameter and no isa" );

    ::is( ::exception {
        has child_d => (
            isa     => "ChildD",
            is      => "ro",
            default => sub { ChildD->new },
            handles => sub {
                my ( $class, $delegate_class ) = @_;
                return;
            }
        );
    }, undef, "can't create attr with generative handles parameter and no isa" );

    ::is( ::exception {
        has child_e => (
            isa     => "ChildE",
            is      => "ro",
            default => sub { ChildE->new },
            handles => ["child_e_method_2"],
        );
    }, undef, "can delegate to non moose class using explicit method list" );

    my $delegate_class;
    ::is( ::exception {
        has child_f => (
            isa     => "ChildF",
            is      => "ro",
            default => sub { ChildF->new },
            handles => sub {
                $delegate_class = $_[1]->name;
                return;
            },
        );
    }, undef, "subrefs on non moose class give no meta" );

    ::is( $delegate_class, "ChildF", "plain classes are handed down to subs" );

    ::is( ::exception {
        has child_g => (
            isa     => "ChildG",
            default => sub { ChildG->new },
            handles => ["child_g_method_1"],
        );
    }, undef, "can delegate to object even without explicit reader" );

    ::can_ok('Parent', 'parent_method_1');
    ::isnt( ::exception {
        has child_h => (
            isa     => "ChildH",
            is      => "ro",
            default => sub { ChildH->new },
            handles => sub { map { $_, $_ } $_[1]->get_all_method_names },
        );
    }, undef, "Can't override exisiting class method in delegate" );
    ::can_ok('Parent', 'parent_method_1');

    ::is( ::exception {
        has child_i => (
            isa     => "ChildI",
            is      => "ro",
            default => sub { ChildI->new },
            handles => sub {
                map { $_, $_ } grep { !/^parent_method_1|meta$/ }
                    $_[1]->get_all_method_names;
            },
        );
    }, undef, "Test handles code ref for skipping predefined methods" );


    sub parent_method { "p" }
}

# sanity

isa_ok( my $p = Parent->new, "Parent" );
isa_ok( $p->child_a, "ChildA" );
isa_ok( $p->child_b, "ChildB" );
isa_ok( $p->child_c, "ChildC" );
isa_ok( $p->child_d, "ChildD" );
isa_ok( $p->child_e, "ChildE" );
isa_ok( $p->child_f, "ChildF" );
isa_ok( $p->child_i, "ChildI" );

ok(!$p->can('child_g'), '... no child_g accessor defined');
ok(!$p->can('child_h'), '... no child_h accessor defined');


is( $p->parent_method, "p", "parent method" );
is( $p->child_a->child_a_super_method, "as", "child supermethod" );
is( $p->child_a->child_a_method_1, "a1", "child method" );

can_ok( $p, "child_a_super_method" );
can_ok( $p, "child_a_method_1" );
can_ok( $p, "child_a_method_2" );
ok( !$p->can( "child_a_method_3" ), "but not subclass of delegate class" );

is( $p->child_a_method_1, $p->child_a->child_a_method_1, "delegate behaves the same" );
is( $p->child_a_method_2, "ChildA a2", "delegates are their own invocants" );


can_ok( $p, "child_b_method_1" );
ok( !$p->can("child_b_method_2"), "but not ChildB's unspecified siblings" );


ok( !$p->can($_), "none of ChildD's methods ($_)" )
    for grep { /^child/ } map { $_->name } ChildD->meta->get_all_methods();

can_ok( $p, "child_c_method_3_la" );
can_ok( $p, "child_c_method_4_la" );

is( $p->child_c_method_3_la, "c3", "ChildC method delegated OK" );

can_ok( $p, "child_e_method_2" );
ok( !$p->can("child_e_method_1"), "but not child_e_method_1");

is( $p->child_e_method_2, "e2", "delegate to non moose class (child_e_method_2)" );

can_ok( $p, "child_g_method_1" );
is( $p->child_g_method_1, "g1", "delegate to moose class without reader (child_g_method_1)" );

can_ok( $p, "child_i_method_1" );
is( $p->parent_method_1, "parent_1", "delegate doesn't override existing method" );

done_testing;
