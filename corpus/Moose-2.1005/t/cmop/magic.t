# Testing magical scalars (using tied scalar)
# Note that XSUBs do not handle magical scalars automatically.

use strict;
use warnings;

use Test::More;
use Test::Fatal;

use Class::Load qw( is_class_loaded load_class );
use Class::MOP;

use Tie::Scalar;

{
    package Foo;
    use metaclass;

    Foo->meta->add_attribute('bar' =>
        reader => 'get_bar',
        writer => 'set_bar',
    );

    Foo->meta->add_attribute('baz' =>
        accessor => 'baz',
    );

    Foo->meta->make_immutable();
}

{
    tie my $foo, 'Tie::StdScalar', Foo->new(bar => 100, baz => 200);

    is $foo->get_bar, 100, 'reader with tied self';
    is $foo->baz,     200, 'accessor/r with tied self';

    $foo->set_bar(300);
    $foo->baz(400);

    is $foo->get_bar, 300, 'writer with tied self';
    is $foo->baz,     400, 'accessor/w with tied self';
}

{
    my $foo = Foo->new();

    tie my $value, 'Tie::StdScalar', 42;

    $foo->set_bar($value);
    $foo->baz($value);

    is $foo->get_bar, 42, 'reader/writer with tied value';
    is $foo->baz,     42, 'accessor with tied value';
}

{
    my $x = tie my $value, 'Tie::StdScalar', 'Class::MOP';

    is( exception { load_class($value) }, undef, 'load_class(tied scalar)' );

    $value = undef;
    $x->STORE('Class::MOP'); # reset

    is( exception {
        ok is_class_loaded($value);
    }, undef, 'is_class_loaded(tied scalar)' );

    $value = undef;
    $x->STORE(\&Class::MOP::get_code_info); # reset

    is( exception {
        is_deeply [Class::MOP::get_code_info($value)], [qw(Class::MOP get_code_info)], 'get_code_info(tied scalar)';
    }, undef );
}

done_testing;
