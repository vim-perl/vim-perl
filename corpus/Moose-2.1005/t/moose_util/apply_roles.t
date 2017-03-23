use strict;
use warnings;

use Test::More;
use Moose::Util qw( apply_all_roles );

{
    package Role::Foo;
    use Moose::Role;
}

{
    package Role::Bar;
    use Moose::Role;
}

{
    package Role::Baz;
    use Moose::Role;
}

{
    package Class::A;
    use Moose;
}

{
    package Class::B;
    use Moose;
}

{
    package Class::C;
    use Moose;
}

{
    package Class::D;
    use Moose;
}

{
    package Class::E;
    use Moose;
}

my @roles = qw( Role::Foo Role::Bar Role::Baz );
apply_all_roles( 'Class::A', @roles );
ok( Class::A->meta->does_role($_), "Class::A does $_" ) for @roles;

apply_all_roles( 'Class::B', map { $_->meta } @roles );
ok( Class::A->meta->does_role($_),
    "Class::B does $_ (applied with meta role object)" )
    for @roles;

@roles = qw( Role::Foo );
apply_all_roles( 'Class::C', @roles );
ok( Class::A->meta->does_role($_), "Class::C does $_" ) for @roles;

apply_all_roles( 'Class::D', map { $_->meta } @roles );
ok( Class::A->meta->does_role($_),
    "Class::D does $_ (applied with meta role object)" )
    for @roles;

@roles = qw( Role::Foo Role::Bar ), Role::Baz->meta;
apply_all_roles( 'Class::E', @roles );
ok( Class::A->meta->does_role($_),
    "Class::E does $_ (mix of names and meta role object)" )
    for @roles;

done_testing;
