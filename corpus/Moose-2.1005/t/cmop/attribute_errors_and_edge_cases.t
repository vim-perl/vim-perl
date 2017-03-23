use strict;
use warnings;

use Test::More;
use Test::Fatal;

use Class::MOP;
use Class::MOP::Attribute;

# most values are static

{
    isnt( exception {
        Class::MOP::Attribute->new('$test' => (
            default => qr/hello (.*)/
        ));
    }, undef, '... no refs for defaults' );

    isnt( exception {
        Class::MOP::Attribute->new('$test' => (
            default => []
        ));
    }, undef, '... no refs for defaults' );

    isnt( exception {
        Class::MOP::Attribute->new('$test' => (
            default => {}
        ));
    }, undef, '... no refs for defaults' );


    isnt( exception {
        Class::MOP::Attribute->new('$test' => (
            default => \(my $var)
        ));
    }, undef, '... no refs for defaults' );

    isnt( exception {
        Class::MOP::Attribute->new('$test' => (
            default => bless {} => 'Foo'
        ));
    }, undef, '... no refs for defaults' );

}

{
    isnt( exception {
        Class::MOP::Attribute->new('$test' => (
            builder => qr/hello (.*)/
        ));
    }, undef, '... no refs for builders' );

    isnt( exception {
        Class::MOP::Attribute->new('$test' => (
            builder => []
        ));
    }, undef, '... no refs for builders' );

    isnt( exception {
        Class::MOP::Attribute->new('$test' => (
            builder => {}
        ));
    }, undef, '... no refs for builders' );


    isnt( exception {
        Class::MOP::Attribute->new('$test' => (
            builder => \(my $var)
        ));
    }, undef, '... no refs for builders' );

    isnt( exception {
        Class::MOP::Attribute->new('$test' => (
            builder => bless {} => 'Foo'
        ));
    }, undef, '... no refs for builders' );

    isnt( exception {
        Class::MOP::Attribute->new('$test' => (
            builder => 'Foo', default => 'Foo'
        ));
    }, undef, '... no default AND builder' );

    my $undef_attr;
    is( exception {
        $undef_attr = Class::MOP::Attribute->new('$test' => (
            default   => undef,
            predicate => 'has_test',
        ));
    }, undef, '... undef as a default is okay' );
    ok($undef_attr->has_default, '... and it counts as an actual default');
    ok(!Class::MOP::Attribute->new('$test')->has_default,
       '... but attributes with no default have no default');

    Class::MOP::Class->create(
        'Foo',
        attributes => [$undef_attr],
    );
    {
        my $obj = Foo->meta->new_object;
        ok($obj->has_test, '... and the default is populated');
        is($obj->meta->get_attribute('$test')->get_value($obj), undef, '... with the right value');
    }
    is( exception { Foo->meta->make_immutable }, undef, '... and it can be inlined' );
    {
        my $obj = Foo->new;
        ok($obj->has_test, '... and the default is populated');
        is($obj->meta->get_attribute('$test')->get_value($obj), undef, '... with the right value');
    }

}


{ # bad construtor args
    isnt( exception {
        Class::MOP::Attribute->new();
    }, undef, '... no name argument' );

    # These are no longer errors
    is( exception {
        Class::MOP::Attribute->new('');
    }, undef, '... bad name argument' );

    is( exception {
        Class::MOP::Attribute->new(0);
    }, undef, '... bad name argument' );
}

{
    my $attr = Class::MOP::Attribute->new('$test');
    isnt( exception {
        $attr->attach_to_class();
    }, undef, '... attach_to_class died as expected' );

    isnt( exception {
        $attr->attach_to_class('Fail');
    }, undef, '... attach_to_class died as expected' );

    isnt( exception {
        $attr->attach_to_class(bless {} => 'Fail');
    }, undef, '... attach_to_class died as expected' );
}

{
    my $attr = Class::MOP::Attribute->new('$test' => (
        reader => [ 'whoops, this wont work' ]
    ));

    $attr->attach_to_class(Class::MOP::Class->initialize('Foo'));

    isnt( exception {
        $attr->install_accessors;
    }, undef, '... bad reader format' );
}

{
    my $attr = Class::MOP::Attribute->new('$test');

    isnt( exception {
        $attr->_process_accessors('fail', 'my_failing_sub');
    }, undef, '... cannot find "fail" type generator' );
}


{
    {
        package My::Attribute;
        our @ISA = ('Class::MOP::Attribute');
        sub generate_reader_method { eval { die } }
    }

    my $attr = My::Attribute->new('$test' => (
        reader => 'test'
    ));

    isnt( exception {
        $attr->install_accessors;
    }, undef, '... failed to generate accessors correctly' );
}

{
    my $attr = Class::MOP::Attribute->new('$test' => (
        predicate => 'has_test'
    ));

    my $Bar = Class::MOP::Class->create('Bar');
    isa_ok($Bar, 'Class::MOP::Class');

    $Bar->add_attribute($attr);

    can_ok('Bar', 'has_test');

    is($attr, $Bar->remove_attribute('$test'), '... removed the $test attribute');

    ok(!Bar->can('has_test'), '... Bar no longer has the "has_test" method');
}


{
    # NOTE:
    # the next three tests once tested that
    # the code would fail, but we lifted the
    # restriction so you can have an accessor
    # along with a reader/writer pair (I mean
    # why not really). So now they test that
    # it works, which is kinda silly, but it
    # tests the API change, so I keep it.

    is( exception {
        Class::MOP::Attribute->new('$foo', (
            accessor => 'foo',
            reader   => 'get_foo',
        ));
    }, undef, '... can create accessors with reader/writers' );

    is( exception {
        Class::MOP::Attribute->new('$foo', (
            accessor => 'foo',
            writer   => 'set_foo',
        ));
    }, undef, '... can create accessors with reader/writers' );

    is( exception {
        Class::MOP::Attribute->new('$foo', (
            accessor => 'foo',
            reader   => 'get_foo',
            writer   => 'set_foo',
        ));
    }, undef, '... can create accessors with reader/writers' );
}

done_testing;
