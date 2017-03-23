use strict;
use warnings;

use Test::More;
use Test::Fatal;

use Moose::Util qw( find_meta );

{
    package RoleA;
    use Moose::Role;

    sub foo { 42 }
}

{
    package RoleB;
    use Moose::Role;

    with 'RoleA';
}

{
    package RoleC;
    use Moose::Role;

    sub foo { 84 }
}

{
    my $composite
        = Moose::Meta::Role->combine( map { [ find_meta($_) => {} ] }
            qw( RoleA RoleB RoleC ) );
    ok( $composite->requires_method('foo'), 'Composite of [ABC] requires a foo method' );
    ok( ! $composite->has_method('foo'), 'Composite of [ABC] does not also have a foo method' );
}

{
    my $composite
        = Moose::Meta::Role->combine( map { [ find_meta($_) => {} ] }
            qw( RoleA RoleC RoleB ) );
    ok( $composite->requires_method('foo'), 'Composite of [ACB] requires a foo method' );
    ok( ! $composite->has_method('foo'), 'Composite of [ACB] does not also have a foo method' );
}

done_testing;
