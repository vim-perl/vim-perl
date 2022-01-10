use strict;
use warnings;
{
    package ParentClass;
    use Moose;
}
{
    package SomeClass;
    use base 'ParentClass';
}
{
    package SubClassUseBase;
    use base qw/SomeClass/;
    use Moose;
}

use Test::More;
use Test::Fatal;

is( exception {
    Moose->init_meta(for_class => 'SomeClass');
}, undef, 'Moose class => use base => Moose Class, then Moose->init_meta on middle class ok' );

done_testing;
