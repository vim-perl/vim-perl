use strict;
use warnings;
use Test::More;

{
    package Foo;
    use Moose::Role;

    use overload
        q{""}    => sub { 42 },
        fallback => 1;

    no Moose::Role;
}

{
    package Bar;
    use Moose;
    with 'Foo';
    no Moose;
}

my $bar = Bar->new;

TODO: {
    local $TODO = "the special () method isn't properly composed into the class";
    is("$bar", 42, 'overloading can be composed');
}

done_testing;
