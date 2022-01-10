use strict;
use warnings;
use Test::More;
use Class::MOP ();

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
    use Moose;
    use Test::More;
    use Test::Fatal;
    is( exception {
        extends 'SubClassUseBase';
    }, undef, 'Can extend non-Moose class with parent class that is a Moose class with a meta role' );
}

{
    ok( SubSubClassUseBase->meta->meta->can('does_role')
        && SubSubClassUseBase->meta->meta->does_role('My::Role'),
        'SubSubClassUseBase meta metaclass does the My::Role role' );
}

# Note, remove metaclasses of the 'use base' classes after each test,
# so that they have to be re-initialized - otherwise latter tests
# would not demonstrate the original issue.
Class::MOP::remove_metaclass_by_name('SubClassUseBase');

{
    package OtherClass;
    use Moose;
}

{
    package OtherSubClassUseBase;
    use base 'OtherClass';
}

{
    package MultiParent1;
    use Moose;
    use Test::More;
    use Test::Fatal;
    is( exception {
        extends qw( SubClassUseBase OtherSubClassUseBase );
    }, undef, 'Can extend two non-Moose classes with parents that are different Moose metaclasses' );
}

{
    ok( MultiParent1->meta->meta->can('does_role')
        && MultiParent1->meta->meta->does_role('My::Role'),
        'MultiParent1 meta metaclass does the My::Role role' );
}

Class::MOP::remove_metaclass_by_name($_)
    for qw( SubClassUseBase OtherSubClassUseBase );

{
    package MultiParent2;
    use Moose;
    use Test::More;
    use Test::Fatal;
    is( exception {
        extends qw( OtherSubClassUseBase SubClassUseBase );
    }, undef, 'Can extend two non-Moose classes with parents that are different Moose metaclasses (reverse order)' );
}

{
    ok( MultiParent2->meta->meta->can('does_role')
        && MultiParent2->meta->meta->does_role('My::Role'),
        'MultiParent2 meta metaclass does the My::Role role' );
}

Class::MOP::remove_metaclass_by_name($_)
    for qw( SubClassUseBase OtherSubClassUseBase );

{
    package MultiParent3;
    use Moose;
    use Test::More;
    use Test::Fatal;
    is( exception {
        extends qw( OtherClass SubClassUseBase );
    }, undef, 'Can extend one Moose class and one non-Moose class' );
}

{
    ok( MultiParent3->meta->meta->can('does_role')
        && MultiParent3->meta->meta->does_role('My::Role'),
        'MultiParent3 meta metaclass does the My::Role role' );
}

Class::MOP::remove_metaclass_by_name($_)
    for qw( SubClassUseBase OtherSubClassUseBase );

{
    package MultiParent4;
    use Moose;
    use Test::More;
    use Test::Fatal;
    is( exception {
        extends qw( SubClassUseBase OtherClass );
    }, undef, 'Can extend one non-Moose class and one Moose class' );
}

{
    ok( MultiParent4->meta->meta->can('does_role')
        && MultiParent4->meta->meta->does_role('My::Role'),
        'MultiParent4 meta metaclass does the My::Role role' );
}

Class::MOP::remove_metaclass_by_name($_)
    for qw( SubClassUseBase OtherSubClassUseBase );

{
    package MultiChild1;
    use Moose;
    use Test::More;
    use Test::Fatal;
    is( exception {
        extends 'MultiParent1';
    }, undef, 'Can extend class that itself extends two non-Moose classes with Moose parents' );
}

{
    ok( MultiChild1->meta->meta->can('does_role')
        && MultiChild1->meta->meta->does_role('My::Role'),
        'MultiChild1 meta metaclass does the My::Role role' );
}

Class::MOP::remove_metaclass_by_name($_)
    for qw( SubClassUseBase OtherSubClassUseBase );

{
    package MultiChild2;
    use Moose;
    use Test::More;
    use Test::Fatal;
    is( exception {
        extends 'MultiParent2';
    }, undef, 'Can extend class that itself extends two non-Moose classes with Moose parents (reverse order)' );
}

{
    ok( MultiChild2->meta->meta->can('does_role')
        && MultiChild2->meta->meta->does_role('My::Role'),
        'MultiChild2 meta metaclass does the My::Role role' );
}

Class::MOP::remove_metaclass_by_name($_)
    for qw( SubClassUseBase OtherSubClassUseBase );

{
    package MultiChild3;
    use Moose;
    use Test::More;
    use Test::Fatal;
    is( exception {
        extends 'MultiParent3';
    }, undef, 'Can extend class that itself extends one Moose and one non-Moose parent' );
}

{
    ok( MultiChild3->meta->meta->can('does_role')
        && MultiChild3->meta->meta->does_role('My::Role'),
        'MultiChild3 meta metaclass does the My::Role role' );
}

Class::MOP::remove_metaclass_by_name($_)
    for qw( SubClassUseBase OtherSubClassUseBase );

{
    package MultiChild4;
    use Moose;
    use Test::More;
    use Test::Fatal;
    is( exception {
        extends 'MultiParent4';
    }, undef, 'Can extend class that itself extends one non-Moose and one Moose parent' );
}

{
    ok( MultiChild4->meta->meta->can('does_role')
        && MultiChild4->meta->meta->does_role('My::Role'),
        'MultiChild4 meta metaclass does the My::Role role' );
}

Class::MOP::remove_metaclass_by_name($_)
    for qw( SubClassUseBase OtherSubClassUseBase );

done_testing;
