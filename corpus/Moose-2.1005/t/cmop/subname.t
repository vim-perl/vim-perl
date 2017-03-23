use strict;
use warnings;

use Test::More;

use Class::MOP;

{

    package Origin;
    sub bar { ( caller(0) )[3] }

    package Foo;
}

my $Foo = Class::MOP::Class->initialize('Foo');

$Foo->add_method( foo => sub { ( caller(0) )[3] } );

is_deeply(
    [ Class::MOP::get_code_info( $Foo->get_method('foo')->body ) ],
    [ "Foo", "foo" ],
    "subname applied to anonymous method",
);

is( Foo->foo, "Foo::foo", "caller() aggrees" );

$Foo->add_method( bar => \&Origin::bar );

is( Origin->bar, "Origin::bar", "normal caller() operation in unrelated class" );

is_deeply(
    [ Class::MOP::get_code_info( $Foo->get_method('foo')->body ) ],
    [ "Foo", "foo" ],
    "subname not applied if a name already exists",
);

is( Foo->bar, "Origin::bar", "caller aggrees" );

is( Origin->bar, "Origin::bar", "unrelated class untouched" );

done_testing;
