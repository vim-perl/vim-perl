use strict;
use warnings;
{
    package My::Role;
    use Moose::Role;
}
{
    package SomeClass;
    use Moose -traits => 'My::Role';
}
{
    package SubClassUseBase;
    use base qw/SomeClass/;
}
{
    package SubSubClassUseBase;
    use base qw/SubClassUseBase/;
}

use Test::More;
use Moose::Util qw/find_meta does_role/;

my $subsubclass_meta = Moose->init_meta( for_class => 'SubSubClassUseBase' );
ok does_role($subsubclass_meta, 'My::Role'),
    'SubSubClass metaclass does role from grandparent metaclass';
my $subclass_meta = find_meta('SubClassUseBase');
ok does_role($subclass_meta, 'My::Role'),
    'SubClass metaclass does role from parent metaclass';

done_testing;
