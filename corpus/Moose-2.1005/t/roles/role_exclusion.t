#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;

=pod

The idea and examples for this feature are taken
from the Fortress spec.

http://research.sun.com/projects/plrg/fortress0903.pdf

trait OrganicMolecule extends Molecule
    excludes { InorganicMolecule }
end
trait InorganicMolecule extends Molecule end

=cut

{
    package Molecule;
    use Moose::Role;

    package Molecule::Organic;
    use Moose::Role;

    with 'Molecule';
    excludes 'Molecule::Inorganic';

    package Molecule::Inorganic;
    use Moose::Role;

    with 'Molecule';
}

ok(Molecule::Organic->meta->excludes_role('Molecule::Inorganic'), '... Molecule::Organic exludes Molecule::Inorganic');
is_deeply(
   [ Molecule::Organic->meta->get_excluded_roles_list() ],
   [ 'Molecule::Inorganic' ],
   '... Molecule::Organic exludes Molecule::Inorganic');

=pod

Check some basic conflicts when combining
the roles into the same class

=cut

{
    package My::Test1;
    use Moose;

    ::is( ::exception {
        with 'Molecule::Organic';
    }, undef, '... adding the role (w/ excluded roles) okay' );

    package My::Test2;
    use Moose;

    ::like( ::exception {
        with 'Molecule::Organic', 'Molecule::Inorganic';
    }, qr/Conflict detected: Role Molecule::Organic excludes role 'Molecule::Inorganic'/, '... adding the role w/ excluded role conflict dies okay' );

    package My::Test3;
    use Moose;

    ::is( ::exception {
        with 'Molecule::Organic';
    }, undef, '... adding the role (w/ excluded roles) okay' );

    ::like( ::exception {
        with 'Molecule::Inorganic';
    }, qr/Conflict detected: My::Test3 excludes role 'Molecule::Inorganic'/, '... adding the role w/ excluded role conflict dies okay' );
}

ok(My::Test1->does('Molecule::Organic'), '... My::Test1 does Molecule::Organic');
ok(My::Test1->does('Molecule'), '... My::Test1 does Molecule');
ok(My::Test1->meta->excludes_role('Molecule::Inorganic'), '... My::Test1 excludes Molecule::Organic');

ok(!My::Test2->does('Molecule::Organic'), '... ! My::Test2 does Molecule::Organic');
ok(!My::Test2->does('Molecule::Inorganic'), '... ! My::Test2 does Molecule::Inorganic');

ok(My::Test3->does('Molecule::Organic'), '... My::Test3 does Molecule::Organic');
ok(My::Test3->does('Molecule'), '... My::Test1 does Molecule');
ok(My::Test3->meta->excludes_role('Molecule::Inorganic'), '... My::Test3 excludes Molecule::Organic');
ok(!My::Test3->does('Molecule::Inorganic'), '... ! My::Test3 does Molecule::Inorganic');

=pod

Check some basic conflicts when combining
the roles into the a superclass

=cut

{
    package Methane;
    use Moose;

    with 'Molecule::Organic';

    package My::Test4;
    use Moose;

    extends 'Methane';

    ::like( ::exception {
        with 'Molecule::Inorganic';
    }, qr/Conflict detected: My::Test4 excludes role \'Molecule::Inorganic\'/, '... cannot add exculded role into class which extends Methane' );
}

ok(Methane->does('Molecule::Organic'), '... Methane does Molecule::Organic');
ok(My::Test4->isa('Methane'), '... My::Test4 isa Methane');
ok(My::Test4->does('Molecule::Organic'), '... My::Test4 does Molecule::Organic');
ok(My::Test4->meta->does_role('Molecule::Organic'), '... My::Test4 meat does_role Molecule::Organic');
ok(My::Test4->meta->excludes_role('Molecule::Inorganic'), '... My::Test4 meta excludes Molecule::Organic');
ok(!My::Test4->does('Molecule::Inorganic'), '... My::Test4 does Molecule::Inorganic');

done_testing;
