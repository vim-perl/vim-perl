use strict;
use warnings;
use Test::More;

our @applications;

{
    package CustomApplication;
    use Moose::Role;

    after apply_methods => sub {
        my ( $self, $role, $other ) = @_;
        $self->apply_custom( $role, $other );
    };

    sub apply_custom {
        shift;
        push @applications, [@_];
    }
}

{
    package CustomApplication::ToClass;
    use Moose::Role;

    with 'CustomApplication';
}

{
    package CustomApplication::ToRole;
    use Moose::Role;

    with 'CustomApplication';
}

{
    package CustomApplication::ToInstance;
    use Moose::Role;

    with 'CustomApplication';
}

{
    package CustomApplication::Composite;
    use Moose::Role;

    with 'CustomApplication';

    around apply_custom => sub {
        my ( $next, $self, $composite, $other ) = @_;
        for my $role ( @{ $composite->get_roles } ) {
            $self->$next( $role, $other );
        }
    };
}

{
    package CustomApplication::Composite::ToClass;
    use Moose::Role;

    with 'CustomApplication::Composite';
}

{
    package CustomApplication::Composite::ToRole;
    use Moose::Role;

    with 'CustomApplication::Composite';
}

{
    package CustomApplication::Composite::ToInstance;
    use Moose::Role;

    with 'CustomApplication::Composite';
}

{
    package Role::Composite;
    use Moose::Role;

    around apply_params => sub {
        my ( $next, $self, @args ) = @_;
        return Moose::Util::MetaRole::apply_metaroles(
            for            => $self->$next(@args),
            role_metaroles => {
                application_to_class =>
                    ['CustomApplication::Composite::ToClass'],
                application_to_role =>
                    ['CustomApplication::Composite::ToRole'],
                application_to_instance =>
                    ['CustomApplication::Composite::ToInstance'],
            },
        );
    };
}

{
    package Role::WithCustomApplication;
    use Moose::Role;

    around composition_class_roles => sub {
        my ($orig, $self) = @_;
        return $self->$orig, 'Role::Composite';
    };
}

{
    package CustomRole;
    Moose::Exporter->setup_import_methods(
        also => 'Moose::Role',
    );

    sub init_meta {
        my ( $self, %options ) = @_;
        return Moose::Util::MetaRole::apply_metaroles(
            for            => Moose::Role->init_meta(%options),
            role_metaroles => {
                role => ['Role::WithCustomApplication'],
                application_to_class =>
                    ['CustomApplication::ToClass'],
                application_to_role => ['CustomApplication::ToRole'],
                application_to_instance =>
                    ['CustomApplication::ToInstance'],
            },
        );
    }
}

{
    package My::Role::Normal;
    use Moose::Role;
}

{
    package My::Role::Special;
    CustomRole->import;
}

ok( My::Role::Normal->meta->isa('Moose::Meta::Role'), "sanity check" );
ok( My::Role::Special->meta->isa('Moose::Meta::Role'),
    "using custom application roles does not change the role metaobject's class"
);
ok( My::Role::Special->meta->meta->does_role('Role::WithCustomApplication'),
    "the role's metaobject has custom applications" );
is_deeply( [My::Role::Special->meta->composition_class_roles],
    ['Role::Composite'],
    "the role knows about the specified composition class" );

{
    package Foo;
    use Moose;

    local @applications;
    with 'My::Role::Special';

    ::is( @applications, 1, 'one role application' );
    ::is( $applications[0]->[0]->name, 'My::Role::Special',
        "the application's first role was My::Role::Special'" );
    ::is( $applications[0]->[1]->name, 'Foo',
        "the application provided an additional role" );
}

{
    package Bar;
    use Moose::Role;

    local @applications;
    with 'My::Role::Special';

    ::is( @applications,               1 );
    ::is( $applications[0]->[0]->name, 'My::Role::Special' );
    ::is( $applications[0]->[1]->name, 'Bar' );
}

{
    package Baz;
    use Moose;

    my $i = Baz->new;
    local @applications;
    My::Role::Special->meta->apply($i);

    ::is( @applications,               1 );
    ::is( $applications[0]->[0]->name, 'My::Role::Special' );
    ::ok( $applications[0]->[1]->is_anon_class );
    ::ok( $applications[0]->[1]->name->isa('Baz') );
}

{
    package Corge;
    use Moose;

    local @applications;
    with 'My::Role::Normal', 'My::Role::Special';

    ::is( @applications,               2 );
    ::is( $applications[0]->[0]->name, 'My::Role::Normal' );
    ::is( $applications[0]->[1]->name, 'Corge' );
    ::is( $applications[1]->[0]->name, 'My::Role::Special' );
    ::is( $applications[1]->[1]->name, 'Corge' );
}

{
    package Thud;
    use Moose::Role;

    local @applications;
    with 'My::Role::Normal', 'My::Role::Special';

    ::is( @applications,               2 );
    ::is( $applications[0]->[0]->name, 'My::Role::Normal' );
    ::is( $applications[0]->[1]->name, 'Thud' );
    ::is( $applications[1]->[0]->name, 'My::Role::Special' );
    ::is( $applications[1]->[1]->name, 'Thud' );
}

{
    package Garply;
    use Moose;

    my $i = Garply->new;
    local @applications;
    Moose::Meta::Role->combine(
        [ 'My::Role::Normal'  => undef ],
        [ 'My::Role::Special' => undef ],
    )->apply($i);

    ::is( @applications,               2 );
    ::is( $applications[0]->[0]->name, 'My::Role::Normal' );
    ::ok( $applications[0]->[1]->is_anon_class );
    ::ok( $applications[0]->[1]->name->isa('Garply') );
    ::is( $applications[1]->[0]->name, 'My::Role::Special' );
    ::ok( $applications[1]->[1]->is_anon_class );
    ::ok( $applications[1]->[1]->name->isa('Garply') );
}

done_testing;
