use strict;
use warnings;
use Test::More;
use Class::MOP;


{
    package Foo;

    my $meta = Class::MOP::Class->initialize(__PACKAGE__);

    $@ = 'dollar at';

    $meta->make_immutable;

    ::is( $@, 'dollar at', '$@ is untouched after immutablization' );
}

done_testing;
