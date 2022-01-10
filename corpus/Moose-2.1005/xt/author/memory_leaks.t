use strict;
use warnings;

use Test::More;
use Test::LeakTrace 0.01;
use Test::Memory::Cycle;

use Moose ();
use Moose::Util qw( apply_all_roles );
use Moose::Util::TypeConstraints;

{
    package MyRole;
    use Moose::Role;
    sub myname { "I'm a role" }
}

no_leaks_ok(
    sub {
        Moose::Meta::Class->create_anon_class->new_object;
    },
    'anonymous class with no roles is leak-free'
);

no_leaks_ok(
    sub {
        Moose::Meta::Role->initialize('MyRole2');
    },
    'Moose::Meta::Role->initialize is leak-free'
);

no_leaks_ok(
    sub {
        Moose::Meta::Class->create('MyClass2')->new_object;
    },
    'creating named class is leak-free'
);

{
    local $TODO
        = 'role application leaks because we end up applying the role more than once to the meta object';
    no_leaks_ok(
        sub {
            Moose::Meta::Class->create( 'MyClass', roles => ['MyRole'] );
        },
        'named class with roles is leak-free'
    );

    no_leaks_ok(
        sub {
            Moose::Meta::Role->create( 'MyRole2', roles => ['MyRole'] );
        },
        'named role with roles is leak-free'
    );
}

no_leaks_ok(
    sub {
        my $object = Moose::Meta::Class->create('MyClass2')->new_object;
        apply_all_roles( $object, 'MyRole' );
    },
    'applying role to an instance is leak-free'
);

no_leaks_ok(
    sub {
        Moose::Meta::Role->create_anon_role;
    },
    'anonymous role is leak-free'
);

{
    # fixing this leak currently triggers a bug in Carp
    # we can un-TODO once that fix goes in allowing the leak
    # in Eval::Closure to be fixed
    local $TODO = 'Eval::Closure leaks a bit at the moment';
    no_leaks_ok(
        sub {
            my $meta = Moose::Meta::Class->create_anon_class;
            $meta->make_immutable;
        },
        'making an anon class immutable is leak-free'
    );
}

{
    my $meta3 = Moose::Meta::Class->create('MyClass3');
    memory_cycle_ok( $meta3, 'named metaclass object is cycle-free' );
    memory_cycle_ok( $meta3->new_object, 'MyClass3 object is cycle-free' );

    my $anon_class = Moose::Meta::Class->create_anon_class;
    memory_cycle_ok($anon_class, 'anon metaclass object is cycle-free' );
    memory_cycle_ok( $anon_class->new_object, 'object from anon metaclass is cycle-free' );

    $anon_class->make_immutable;
    memory_cycle_ok($anon_class, 'immutable anon metaclass object is cycle-free' );
    memory_cycle_ok( $anon_class->new_object, 'object from immutable anon metaclass is cycle-free' );

    my $anon_role = Moose::Meta::Role->create_anon_role;
    memory_cycle_ok($anon_role, 'anon role meta object is cycle-free' );
}

{
    my $Str = find_type_constraint('Str');
    my $Undef = find_type_constraint('Undef');
    my $Str_or_Undef = Moose::Meta::TypeConstraint::Union->new(
        type_constraints => [ $Str, $Undef ] );
    memory_cycle_ok($Str_or_Undef, 'union types do not leak');
}


done_testing;
