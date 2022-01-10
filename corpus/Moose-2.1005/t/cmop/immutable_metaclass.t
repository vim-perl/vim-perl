use strict;
use warnings;

use Test::More;
use Test::Fatal;

use Class::MOP;

{
    package Foo;

    use strict;
    use warnings;
    use metaclass;

    __PACKAGE__->meta->add_attribute('bar');

    package Bar;

    use strict;
    use warnings;
    use metaclass;

    __PACKAGE__->meta->superclasses('Foo');

    __PACKAGE__->meta->add_attribute('baz');

    package Baz;

    use strict;
    use warnings;
    use metaclass;

    __PACKAGE__->meta->superclasses('Bar');

    __PACKAGE__->meta->add_attribute('bah');
}

{
    my $meta = Foo->meta;
    my $original_metaclass_name = ref $meta;

    is_deeply(
        { $meta->immutable_options }, {},
        'immutable_options is empty before a class is made_immutable'
    );

    ok( $meta->make_immutable, 'make_immutable returns true' );
    my $line = __LINE__ - 1;

    ok( $meta->make_immutable, 'make_immutable still returns true' );

    my $immutable_metaclass = $meta->_immutable_metaclass->meta;

    my $immutable_class_name = $immutable_metaclass->name;

    ok( !$immutable_class_name->is_mutable,  '... immutable_metaclass is not mutable' );
    ok( $immutable_class_name->is_immutable, '... immutable_metaclass is immutable' );
    is( $immutable_class_name->meta, $immutable_metaclass,
        '... immutable_metaclass meta hack works' );

    is_deeply(
        { $meta->immutable_options },
        {
            inline_accessors   => 1,
            inline_constructor => 1,
            inline_destructor  => 0,
            debug              => 0,
            immutable_trait    => 'Class::MOP::Class::Immutable::Trait',
            constructor_name   => 'new',
            constructor_class  => 'Class::MOP::Method::Constructor',
            destructor_class   => undef,
            file               => $0,
            line               => $line,
        },
        'immutable_options is empty before a class is made_immutable'
    );

    isa_ok( $meta, "Class::MOP::Class" );
}

{
    my $meta = Foo->meta;
    is( $meta->name, 'Foo', '... checking the Foo metaclass' );

    ok( !$meta->is_mutable,    '... our class is not mutable' );
    ok( $meta->is_immutable, '... our class is immutable' );

    isa_ok( $meta, 'Class::MOP::Class' );

    isnt( exception { $meta->add_method() }, undef, '... exception thrown as expected' );
    isnt( exception { $meta->alias_method() }, undef, '... exception thrown as expected' );
    isnt( exception { $meta->remove_method() }, undef, '... exception thrown as expected' );

    isnt( exception { $meta->add_attribute() }, undef, '... exception thrown as expected' );
    isnt( exception { $meta->remove_attribute() }, undef, '... exception thrown as expected' );

    isnt( exception { $meta->add_package_symbol() }, undef, '... exception thrown as expected' );
    isnt( exception { $meta->remove_package_symbol() }, undef, '... exception thrown as expected' );

    is( exception { $meta->identifier() }, undef, '... no exception for get_package_symbol special case' );

    my @supers;
    is( exception {
        @supers = $meta->superclasses;
    }, undef, '... got the superclasses okay' );

    isnt( exception { $meta->superclasses( ['UNIVERSAL'] ) }, undef, '... but could not set the superclasses okay' );

    my $meta_instance;
    is( exception {
        $meta_instance = $meta->get_meta_instance;
    }, undef, '... got the meta instance okay' );
    isa_ok( $meta_instance, 'Class::MOP::Instance' );
    is( $meta_instance, $meta->get_meta_instance,
        '... and we know it is cached' );

    my @cpl;
    is( exception {
        @cpl = $meta->class_precedence_list;
    }, undef, '... got the class precedence list okay' );
    is_deeply(
        \@cpl,
        ['Foo'],
        '... we just have ourselves in the class precedence list'
    );

    my @attributes;
    is( exception {
        @attributes = $meta->get_all_attributes;
    }, undef, '... got the attribute list okay' );
    is_deeply(
        \@attributes,
        [ $meta->get_attribute('bar') ],
        '... got the right list of attributes'
    );
}

{
    my $meta = Bar->meta;
    is( $meta->name, 'Bar', '... checking the Bar metaclass' );

    ok( $meta->is_mutable,    '... our class is mutable' );
    ok( !$meta->is_immutable, '... our class is not immutable' );

    is( exception {
        $meta->make_immutable();
    }, undef, '... changed Bar to be immutable' );

    ok( $meta->make_immutable, '... make immutable returns true' );

    ok( !$meta->is_mutable,  '... our class is no longer mutable' );
    ok( $meta->is_immutable, '... our class is now immutable' );

    isa_ok( $meta, 'Class::MOP::Class' );

    isnt( exception { $meta->add_method() }, undef, '... exception thrown as expected' );
    isnt( exception { $meta->alias_method() }, undef, '... exception thrown as expected' );
    isnt( exception { $meta->remove_method() }, undef, '... exception thrown as expected' );

    isnt( exception { $meta->add_attribute() }, undef, '... exception thrown as expected' );
    isnt( exception { $meta->remove_attribute() }, undef, '... exception thrown as expected' );

    isnt( exception { $meta->add_package_symbol() }, undef, '... exception thrown as expected' );
    isnt( exception { $meta->remove_package_symbol() }, undef, '... exception thrown as expected' );

    my @supers;
    is( exception {
        @supers = $meta->superclasses;
    }, undef, '... got the superclasses okay' );

    isnt( exception { $meta->superclasses( ['UNIVERSAL'] ) }, undef, '... but could not set the superclasses okay' );

    my $meta_instance;
    is( exception {
        $meta_instance = $meta->get_meta_instance;
    }, undef, '... got the meta instance okay' );
    isa_ok( $meta_instance, 'Class::MOP::Instance' );
    is( $meta_instance, $meta->get_meta_instance,
        '... and we know it is cached' );

    my @cpl;
    is( exception {
        @cpl = $meta->class_precedence_list;
    }, undef, '... got the class precedence list okay' );
    is_deeply(
        \@cpl,
        [ 'Bar', 'Foo' ],
        '... we just have ourselves in the class precedence list'
    );

    my @attributes;
    is( exception {
        @attributes = $meta->get_all_attributes;
    }, undef, '... got the attribute list okay' );
    is_deeply(
        [ sort { $a->name cmp $b->name } @attributes ],
        [ Foo->meta->get_attribute('bar'), $meta->get_attribute('baz') ],
        '... got the right list of attributes'
    );
}

{
    my $meta = Baz->meta;
    is( $meta->name, 'Baz', '... checking the Baz metaclass' );

    ok( $meta->is_mutable,    '... our class is mutable' );
    ok( !$meta->is_immutable, '... our class is not immutable' );

    is( exception {
        $meta->make_immutable();
    }, undef, '... changed Baz to be immutable' );

    ok( $meta->make_immutable, '... make immutable returns true' );

    ok( !$meta->is_mutable,  '... our class is no longer mutable' );
    ok( $meta->is_immutable, '... our class is now immutable' );

    isa_ok( $meta, 'Class::MOP::Class' );

    isnt( exception { $meta->add_method() }, undef, '... exception thrown as expected' );
    isnt( exception { $meta->alias_method() }, undef, '... exception thrown as expected' );
    isnt( exception { $meta->remove_method() }, undef, '... exception thrown as expected' );

    isnt( exception { $meta->add_attribute() }, undef, '... exception thrown as expected' );
    isnt( exception { $meta->remove_attribute() }, undef, '... exception thrown as expected' );

    isnt( exception { $meta->add_package_symbol() }, undef, '... exception thrown as expected' );
    isnt( exception { $meta->remove_package_symbol() }, undef, '... exception thrown as expected' );

    my @supers;
    is( exception {
        @supers = $meta->superclasses;
    }, undef, '... got the superclasses okay' );

    isnt( exception { $meta->superclasses( ['UNIVERSAL'] ) }, undef, '... but could not set the superclasses okay' );

    my $meta_instance;
    is( exception {
        $meta_instance = $meta->get_meta_instance;
    }, undef, '... got the meta instance okay' );
    isa_ok( $meta_instance, 'Class::MOP::Instance' );
    is( $meta_instance, $meta->get_meta_instance,
        '... and we know it is cached' );

    my @cpl;
    is( exception {
        @cpl = $meta->class_precedence_list;
    }, undef, '... got the class precedence list okay' );
    is_deeply(
        \@cpl,
        [ 'Baz', 'Bar', 'Foo' ],
        '... we just have ourselves in the class precedence list'
    );

    my @attributes;
    is( exception {
        @attributes = $meta->get_all_attributes;
    }, undef, '... got the attribute list okay' );
    is_deeply(
        [ sort { $a->name cmp $b->name } @attributes ],
        [
            $meta->get_attribute('bah'), Foo->meta->get_attribute('bar'),
            Bar->meta->get_attribute('baz')
        ],
        '... got the right list of attributes'
    );
}

# This test probably needs to go last since it will muck up the Foo class
{
    my $meta = Foo->meta;

    $meta->make_mutable;
    $meta->make_immutable(
        inline_accessors   => 0,
        inline_constructor => 0,
        constructor_name   => 'newer',
    );
    my $line = __LINE__ - 5;

    is_deeply(
        { $meta->immutable_options },
        {
            inline_accessors   => 0,
            inline_constructor => 0,
            inline_destructor  => 0,
            debug              => 0,
            immutable_trait    => 'Class::MOP::Class::Immutable::Trait',
            constructor_name   => 'newer',
            constructor_class  => 'Class::MOP::Method::Constructor',
            destructor_class   => undef,
            file               => $0,
            line               => $line,
        },
        'custom immutable_options are returned by immutable_options accessor'
    );
}

done_testing;
