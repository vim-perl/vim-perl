use strict;
use warnings;

use Test::More;

use Test::Requires {
    'Test::Output' => '0.01', # skip all if not installed
};

use Class::MOP;

{
    package HasConstructor;

    sub new { bless {}, $_[0] }

    my $meta = Class::MOP::Class->initialize(__PACKAGE__);

    $meta->superclasses('NotMoose');

    ::stderr_like(
        sub { $meta->make_immutable },
        qr/\QNot inlining a constructor for HasConstructor since it defines its own constructor.\E\s+\QIf you are certain you don't need to inline your constructor, specify inline_constructor => 0 in your call to HasConstructor->meta->make_immutable\E/,
        'got a warning that Foo will not have an inlined constructor because it defines its own new method'
    );

    ::is(
        $meta->find_method_by_name('new')->body,
        HasConstructor->can('new'),
        'HasConstructor->new was untouched'
    );
}

{
    package My::Constructor;

    use base 'Class::MOP::Method::Constructor';

    sub _expected_method_class { 'Base::Class' }
}

{
    package No::Constructor;
}

{
    package My::Constructor2;

    use base 'Class::MOP::Method::Constructor';

    sub _expected_method_class { 'No::Constructor' }
}

{
    package Base::Class;

    sub new { bless {}, $_[0] }
    sub DESTROY { }
}

{
    package NotMoose;

    sub new {
        my $class = shift;

        return bless { not_moose => 1 }, $class;
    }
}

{
    package Foo;
    my $meta = Class::MOP::Class->initialize(__PACKAGE__);

    $meta->superclasses('NotMoose');

    ::stderr_like(
        sub { $meta->make_immutable( constructor_class => 'My::Constructor' ) },
        qr/\QNot inlining 'new' for Foo since it is not inheriting the default Base::Class::new\E\s+\QIf you are certain you don't need to inline your constructor, specify inline_constructor => 0 in your call to Foo->meta->make_immutable/,
        'got a warning that Foo will not have an inlined constructor'
    );

    ::is(
        $meta->find_method_by_name('new')->body,
        NotMoose->can('new'),
        'Foo->new is inherited from NotMoose'
    );
}

{
    package Bar;
    my $meta = Class::MOP::Class->initialize(__PACKAGE__);

    $meta->superclasses('NotMoose');

    ::stderr_is(
        sub { $meta->make_immutable( replace_constructor => 1 ) },
        q{},
        'no warning when replace_constructor is true'
    );

    ::is(
        $meta->find_method_by_name('new')->package_name,
        'Bar',
        'Bar->new is inlined, and not inherited from NotMoose'
    );
}

{
    package Baz;
    Class::MOP::Class->initialize(__PACKAGE__)->make_immutable;
}

{
    package Quux;
    my $meta = Class::MOP::Class->initialize(__PACKAGE__);

    $meta->superclasses('Baz');

    ::stderr_is(
        sub { $meta->make_immutable },
        q{},
        'no warning when inheriting from a class that has already made itself immutable'
    );
}

{
    package Whatever;
    my $meta = Class::MOP::Class->initialize(__PACKAGE__);

    ::stderr_like(
        sub { $meta->make_immutable( constructor_class => 'My::Constructor2' ) },
        qr/\QNot inlining 'new' for Whatever since No::Constructor::new is not defined/,
        'got a warning that Whatever will not have an inlined constructor because its expected inherited method does not exist'
    );
}

{
    package My::Constructor3;

    use base 'Class::MOP::Method::Constructor';
}

{
    package CustomCons;

    Class::MOP::Class->initialize(__PACKAGE__)->make_immutable( constructor_class => 'My::Constructor3' );
}

{
    package Subclass;
    my $meta = Class::MOP::Class->initialize(__PACKAGE__);

    $meta->superclasses('CustomCons');

    ::stderr_is(
        sub { $meta->make_immutable },
        q{},
        'no warning when inheriting from a class that has already made itself immutable'
    );
}

{
    package ModdedNew;
    my $meta = Class::MOP::Class->initialize(__PACKAGE__);

    sub new { bless {}, shift }

    $meta->add_before_method_modifier( 'new' => sub { } );
}

{
    package ModdedSub;
    my $meta = Class::MOP::Class->initialize(__PACKAGE__);

    $meta->superclasses('ModdedNew');

    ::stderr_like(
        sub { $meta->make_immutable },
        qr/\QNot inlining 'new' for ModdedSub since it has method modifiers which would be lost if it were inlined/,
        'got a warning that ModdedSub will not have an inlined constructor since it inherited a wrapped new'
    );
}

{
    package My::Destructor;

    use base 'Class::MOP::Method::Inlined';

    sub new {
        my $class   = shift;
        my %options = @_;

        my $self = bless \%options, $class;
        $self->_inline_destructor;

        return $self;
    }

    sub _inline_destructor {
        my $self = shift;

        my $code = $self->_compile_code('sub { }');

        $self->{body} = $code;
    }

    sub is_needed { 1 }
    sub associated_metaclass { $_[0]->{metaclass} }
    sub body { $_[0]->{body} }
    sub _expected_method_class { 'Base::Class' }
}

{
    package HasDestructor;
    my $meta = Class::MOP::Class->initialize(__PACKAGE__);

    sub DESTROY { }

    ::stderr_like(
        sub {
            $meta->make_immutable(
                inline_destructor => 1,
                destructor_class  => 'My::Destructor',
            );
        },
        qr/Not inlining a destructor for HasDestructor since it defines its own destructor./,
        'got a warning when trying to inline a destructor for a class that already defines DESTROY'
    );

    ::is(
        $meta->find_method_by_name('DESTROY')->body,
        HasDestructor->can('DESTROY'),
        'HasDestructor->DESTROY was untouched'
    );
}

{
    package HasDestructor2;
    my $meta = Class::MOP::Class->initialize(__PACKAGE__);

    sub DESTROY { }

    $meta->make_immutable(
        inline_destructor  => 1,
        destructor_class   => 'My::Destructor',
        replace_destructor => 1
    );

    ::stderr_is(
        sub {
            $meta->make_immutable(
                inline_destructor  => 1,
                destructor_class   => 'My::Destructor',
                replace_destructor => 1
            );
        },
        q{},
        'no warning when replace_destructor is true'
    );

    ::isnt(
        $meta->find_method_by_name('new')->body,
        HasConstructor2->can('new'),
        'HasConstructor2->new was replaced'
    );
}

{
    package ParentHasDestructor;

    sub DESTROY { }
}

{
    package DestructorChild;

    use base 'ParentHasDestructor';

    my $meta = Class::MOP::Class->initialize(__PACKAGE__);

    ::stderr_like(
        sub {
            $meta->make_immutable(
                inline_destructor => 1,
                destructor_class  => 'My::Destructor',
            );
        },
        qr/Not inlining 'DESTROY' for DestructorChild since it is not inheriting the default Base::Class::DESTROY/,
        'got a warning when trying to inline a destructor in a class that inherits an unexpected DESTROY'
    );
}

done_testing;
