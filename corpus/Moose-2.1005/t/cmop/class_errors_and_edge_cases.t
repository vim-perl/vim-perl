use strict;
use warnings;

use Test::More;
use Test::Fatal;

use Class::MOP;

{
    isnt( exception {
        Class::MOP::Class->initialize();
    }, undef, '... initialize requires a name parameter' );

    isnt( exception {
        Class::MOP::Class->initialize('');
    }, undef, '... initialize requires a name valid parameter' );

    isnt( exception {
        Class::MOP::Class->initialize(bless {} => 'Foo');
    }, undef, '... initialize requires an unblessed parameter' );
}

{
    isnt( exception {
        Class::MOP::Class->_construct_class_instance();
    }, undef, '... _construct_class_instance requires an :package parameter' );

    isnt( exception {
        Class::MOP::Class->_construct_class_instance(':package' => undef);
    }, undef, '... _construct_class_instance requires a defined :package parameter' );

    isnt( exception {
        Class::MOP::Class->_construct_class_instance(':package' => '');
    }, undef, '... _construct_class_instance requires a valid :package parameter' );
}


{
    isnt( exception {
        Class::MOP::Class->create();
    }, undef, '... create requires an package_name parameter' );

    isnt( exception {
        Class::MOP::Class->create(undef);
    }, undef, '... create requires a defined package_name parameter' );

    isnt( exception {
        Class::MOP::Class->create('');
    }, undef, '... create requires a valid package_name parameter' );

    isnt( exception {
        Class::MOP::Class->create('+++');
    }, qr/^\+\+\+ is not a module name/, '... create requires a valid package_name parameter' );
}

{
    isnt( exception {
        Class::MOP::Class->clone_object(1);
    }, undef, '... can only clone instances' );
}

{
    isnt( exception {
        Class::MOP::Class->add_method();
    }, undef, '... add_method dies as expected' );

    isnt( exception {
        Class::MOP::Class->add_method('');
    }, undef, '... add_method dies as expected' );

    isnt( exception {
        Class::MOP::Class->add_method('foo' => 'foo');
    }, undef, '... add_method dies as expected' );

    isnt( exception {
        Class::MOP::Class->add_method('foo' => []);
    }, undef, '... add_method dies as expected' );
}

{
    isnt( exception {
        Class::MOP::Class->has_method();
    }, undef, '... has_method dies as expected' );

    isnt( exception {
        Class::MOP::Class->has_method('');
    }, undef, '... has_method dies as expected' );
}

{
    isnt( exception {
        Class::MOP::Class->get_method();
    }, undef, '... get_method dies as expected' );

    isnt( exception {
        Class::MOP::Class->get_method('');
    }, undef, '... get_method dies as expected' );
}

{
    isnt( exception {
        Class::MOP::Class->remove_method();
    }, undef, '... remove_method dies as expected' );

    isnt( exception {
        Class::MOP::Class->remove_method('');
    }, undef, '... remove_method dies as expected' );
}

{
    isnt( exception {
        Class::MOP::Class->find_all_methods_by_name();
    }, undef, '... find_all_methods_by_name dies as expected' );

    isnt( exception {
        Class::MOP::Class->find_all_methods_by_name('');
    }, undef, '... find_all_methods_by_name dies as expected' );
}

{
    isnt( exception {
        Class::MOP::Class->add_attribute(bless {} => 'Foo');
    }, undef, '... add_attribute dies as expected' );
}


{
    isnt( exception {
        Class::MOP::Class->has_attribute();
    }, undef, '... has_attribute dies as expected' );

    isnt( exception {
        Class::MOP::Class->has_attribute('');
    }, undef, '... has_attribute dies as expected' );
}

{
    isnt( exception {
        Class::MOP::Class->get_attribute();
    }, undef, '... get_attribute dies as expected' );

    isnt( exception {
        Class::MOP::Class->get_attribute('');
    }, undef, '... get_attribute dies as expected' );
}

{
    isnt( exception {
        Class::MOP::Class->remove_attribute();
    }, undef, '... remove_attribute dies as expected' );

    isnt( exception {
        Class::MOP::Class->remove_attribute('');
    }, undef, '... remove_attribute dies as expected' );
}

{
    isnt( exception {
        Class::MOP::Class->add_package_symbol();
    }, undef, '... add_package_symbol dies as expected' );

    isnt( exception {
        Class::MOP::Class->add_package_symbol('');
    }, undef, '... add_package_symbol dies as expected' );

    isnt( exception {
        Class::MOP::Class->add_package_symbol('foo');
    }, undef, '... add_package_symbol dies as expected' );

    isnt( exception {
        Class::MOP::Class->add_package_symbol('&foo');
    }, undef, '... add_package_symbol dies as expected' );

#    throws_ok {
#        Class::MOP::Class->meta->add_package_symbol('@-');
#    } qr/^Could not create package variable \(\@\-\) because/,
#      '... add_package_symbol dies as expected';
}

{
    isnt( exception {
        Class::MOP::Class->has_package_symbol();
    }, undef, '... has_package_symbol dies as expected' );

    isnt( exception {
        Class::MOP::Class->has_package_symbol('');
    }, undef, '... has_package_symbol dies as expected' );

    isnt( exception {
        Class::MOP::Class->has_package_symbol('foo');
    }, undef, '... has_package_symbol dies as expected' );
}

{
    isnt( exception {
        Class::MOP::Class->get_package_symbol();
    }, undef, '... get_package_symbol dies as expected' );

    isnt( exception {
        Class::MOP::Class->get_package_symbol('');
    }, undef, '... get_package_symbol dies as expected' );

    isnt( exception {
        Class::MOP::Class->get_package_symbol('foo');
    }, undef, '... get_package_symbol dies as expected' );
}

{
    isnt( exception {
        Class::MOP::Class->remove_package_symbol();
    }, undef, '... remove_package_symbol dies as expected' );

    isnt( exception {
        Class::MOP::Class->remove_package_symbol('');
    }, undef, '... remove_package_symbol dies as expected' );

    isnt( exception {
        Class::MOP::Class->remove_package_symbol('foo');
    }, undef, '... remove_package_symbol dies as expected' );
}

done_testing;
