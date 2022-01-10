use strict;
use warnings;

use Test::More;
use Moose::Role ();

my $test1 = Moose::Meta::Role->create_anon_role;
$test1->add_method( 'foo1', sub { } );

ok( $test1->has_method('foo1'), 'anon role has a foo1 method' );

my $t1_am = $test1->get_method('foo1')->associated_metaclass;

ok( $t1_am, 'associated_metaclass is defined' );

isa_ok(
    $t1_am, 'Moose::Meta::Role',
    'associated_metaclass is correct class'
);

like( $t1_am->name(), qr/::__ANON__::/,
    'associated_metaclass->name looks like an anonymous class' );

{
    package Test2;

    use Moose::Role;

    sub foo2 { }
}

ok( Test2->meta->has_method('foo2'), 'Test2 role has a foo2 method' );

my $t2_am = Test2->meta->get_method('foo2')->associated_metaclass;

ok( $t2_am, 'associated_metaclass is defined' );

isa_ok(
    $t2_am, 'Moose::Meta::Role',
    'associated_metaclass is correct class'
);

is( $t2_am->name(), 'Test2',
    'associated_metaclass->name is Test2' );

done_testing;
