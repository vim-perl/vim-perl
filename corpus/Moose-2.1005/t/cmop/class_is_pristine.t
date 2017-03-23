use strict;
use warnings;

use Class::MOP;
use Test::More;

{
    package Foo;

    sub foo { }
    sub bar { }
}

my $meta = Class::MOP::Class->initialize('Foo');
ok( $meta->is_pristine, 'Foo is still pristine' );

$meta->add_method( baz => sub { } );
ok( $meta->is_pristine, 'Foo is still pristine after add_method' );

$meta->add_attribute( name => 'attr', reader => 'get_attr' );
ok( ! $meta->is_pristine, 'Foo is not pristine after add_attribute' );

done_testing;
