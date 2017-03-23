#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;

# Some packages out in the wild cooperate with Moose by using goto
# &Moose::import. we want to make sure it still works.

{
    package MooseAlike1;

    use strict;
    use warnings;

    use Moose ();

    sub import {
        goto &Moose::import;
    }

    sub unimport {
        goto &Moose::unimport;
    }
}

{
    package Foo;

    MooseAlike1->import();

    ::is( ::exception { has( 'size', is => 'bare' ) }, undef, 'has was exported via MooseAlike1' );

    MooseAlike1->unimport();
}

ok( ! Foo->can('has'),
    'No has sub in Foo after MooseAlike1 is unimported' );
ok( Foo->can('meta'),
    'Foo has a meta method' );
isa_ok( Foo->meta(), 'Moose::Meta::Class' );


{
    package MooseAlike2;

    use strict;
    use warnings;

    use Moose ();

    my $import = \&Moose::import;
    sub import {
        goto $import;
    }

    my $unimport = \&Moose::unimport;
    sub unimport {
        goto $unimport;
    }
}

{
    package Bar;

    MooseAlike2->import();

    ::is( ::exception { has( 'size', is => 'bare' ) }, undef, 'has was exported via MooseAlike2' );

    MooseAlike2->unimport();
}


ok( ! Bar->can('has'),
          'No has sub in Bar after MooseAlike2 is unimported' );
ok( Bar->can('meta'),
    'Bar has a meta method' );
isa_ok( Bar->meta(), 'Moose::Meta::Class' );

done_testing;
