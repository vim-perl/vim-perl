use strict;
use warnings;

use Test::More;
use Test::Fatal;

use Scalar::Util;

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
    my $meta = Baz->meta;
    is($meta->name, 'Baz', '... checking the Baz metaclass');
    my %orig_keys = map { $_ => 1 } grep { !/^_/ } keys %$meta;
    # Since this has no default it won't be present yet, but it will
    # be after the class is made immutable.

    is( exception {$meta->make_immutable; }, undef, '... changed Baz to be immutable' );
    ok(!$meta->is_mutable,              '... our class is no longer mutable');
    ok($meta->is_immutable,             '... our class is now immutable');
    ok($meta->make_immutable,           '... make immutable returns true');
    ok($meta->get_method('new'),        '... inlined constructor created');
    ok($meta->has_method('new'),        '... inlined constructor created for sure');
    is_deeply([ map { $_->name } $meta->_inlined_methods ], [ 'new' ], '... really, i mean it');

    is( exception { $meta->make_mutable; }, undef, '... changed Baz to be mutable' );
    ok($meta->is_mutable,               '... our class is mutable');
    ok(!$meta->is_immutable,            '... our class is not immutable');
    ok(!$meta->make_mutable,            '... make mutable now returns nothing');
    ok(!$meta->get_method('new'),       '... inlined constructor created');
    ok(!$meta->has_method('new'),       '... inlined constructor removed for sure');

    my %new_keys = map { $_ => 1 } grep { !/^_/ } keys %$meta;
    is_deeply(\%orig_keys, \%new_keys, '... no extraneous hashkeys');

    isa_ok($meta, 'Class::MOP::Class', '... Baz->meta isa Class::MOP::Class');

    $meta->add_method('xyz', sub{'xxx'});
    is( Baz->xyz, 'xxx',                      '... method xyz works');

    ok($meta->add_attribute('fickle', accessor => 'fickle'), '... added attribute');
    ok(Baz->can('fickle'),                '... Baz can fickle');
    ok($meta->remove_attribute('fickle'), '... removed attribute');

    my $reef = \ 'reef';
    $meta->add_package_symbol('$ref', $reef);
    is($meta->get_package_symbol('$ref'), $reef,      '... values match');
    is( exception { $meta->remove_package_symbol('$ref') }, undef, '... removed it' );
    isnt($meta->get_package_symbol('$ref'), $reef,    '... values match');

    ok( my @supers = $meta->superclasses,       '... got the superclasses okay');
    ok( $meta->superclasses('Foo'),             '... set the superclasses');
    is_deeply(['Foo'], [$meta->superclasses],   '... set the superclasses okay');
    ok( $meta->superclasses( @supers ),         '... reset superclasses');
    is_deeply([@supers], [$meta->superclasses], '... reset the superclasses okay');

    ok( $meta->$_  , "... ${_} works")
      for qw(get_meta_instance       get_all_attributes
             class_precedence_list );

    is( exception {$meta->make_immutable; }, undef, '... changed Baz to be immutable again' );
    ok($meta->get_method('new'),    '... inlined constructor recreated');
}

{
    my $meta = Baz->meta;

    is( exception { $meta->make_immutable() }, undef, 'Changed Baz to be immutable' );
    is( exception { $meta->make_mutable() }, undef, '... changed Baz to be mutable' );
    is( exception { $meta->make_immutable() }, undef, '... changed Baz to be immutable' );

    isnt( exception { $meta->add_method('xyz', sub{'xxx'})  }, undef, '... exception thrown as expected' );

    isnt( exception {
      $meta->add_attribute('fickle', accessor => 'fickle')
    }, undef, '... exception thrown as expected' );
    isnt( exception { $meta->remove_attribute('fickle') }, undef, '... exception thrown as expected' );

    my $reef = \ 'reef';
    isnt( exception { $meta->add_package_symbol('$ref', $reef) }, undef, '... exception thrown as expected' );
    isnt( exception { $meta->remove_package_symbol('$ref')     }, undef, '... exception thrown as expected' );

    ok( my @supers = $meta->superclasses,  '... got the superclasses okay');
    isnt( exception { $meta->superclasses('Foo') }, undef, '... set the superclasses' );

    ok( $meta->$_  , "... ${_} works")
      for qw(get_meta_instance       get_all_attributes
             class_precedence_list );
}

{

    ok(Baz->meta->is_immutable,  'Superclass is immutable');
    my $meta = Baz->meta->create_anon_class(superclasses => ['Baz']);
    my %orig_keys = map { $_ => 1 } grep { !/^_/ } keys %$meta;
    my @orig_meths = sort { $a->name cmp $b->name } $meta->get_all_methods;
    ok($meta->is_anon_class,                  'We have an anon metaclass');
    ok($meta->is_mutable,  '... our anon class is mutable');
    ok(!$meta->is_immutable,  '... our anon class is not immutable');

    is( exception {$meta->make_immutable(
                                    inline_accessor    => 1,
                                    inline_destructor  => 0,
                                    inline_constructor => 1,
                                   )
            }, undef, '... changed class to be immutable' );
    ok(!$meta->is_mutable,                    '... our class is no longer mutable');
    ok($meta->is_immutable,                   '... our class is now immutable');
    ok($meta->make_immutable,                 '... make immutable returns true');

    is( exception { $meta->make_mutable }, undef, '... changed Baz to be mutable' );
    ok($meta->is_mutable,             '... our class is mutable');
    ok(!$meta->is_immutable,          '... our class is not immutable');
    ok(!$meta->make_mutable,          '... make mutable now returns nothing');
    ok($meta->is_anon_class,          '... still marked as an anon class');
    my $instance = $meta->new_object;

    my %new_keys  = map { $_ => 1 } grep { !/^_/ } keys %$meta;
    my @new_meths = sort { $a->name cmp $b->name }
      $meta->get_all_methods;
    is_deeply(\%orig_keys, \%new_keys, '... no extraneous hashkeys');
    is_deeply(\@orig_meths, \@new_meths, '... no straneous methods');

    isa_ok($meta, 'Class::MOP::Class', '... Anon class isa Class::MOP::Class');

    $meta->add_method('xyz', sub{'xxx'});
    is( $instance->xyz , 'xxx',               '... method xyz works');
    ok( $meta->remove_method('xyz'),          '... removed method');

    ok($meta->add_attribute('fickle', accessor => 'fickle'), '... added attribute');
    ok($instance->can('fickle'),          '... instance can fickle');
    ok($meta->remove_attribute('fickle'), '... removed attribute');

    my $reef = \ 'reef';
    $meta->add_package_symbol('$ref', $reef);
    is($meta->get_package_symbol('$ref'), $reef,      '... values match');
    is( exception { $meta->remove_package_symbol('$ref') }, undef, '... removed it' );
    isnt($meta->get_package_symbol('$ref'), $reef,    '... values match');

    ok( my @supers = $meta->superclasses,       '... got the superclasses okay');
    ok( $meta->superclasses('Foo'),             '... set the superclasses');
    is_deeply(['Foo'], [$meta->superclasses],   '... set the superclasses okay');
    ok( $meta->superclasses( @supers ),         '... reset superclasses');
    is_deeply([@supers], [$meta->superclasses], '... reset the superclasses okay');

    ok( $meta->$_  , "... ${_} works")
      for qw(get_meta_instance       get_all_attributes
             class_precedence_list );
};


#rerun the same tests on an anon class.. just cause we can.
{
    my $meta = Baz->meta->create_anon_class(superclasses => ['Baz']);

    is( exception {$meta->make_immutable(
                                    inline_accessor    => 1,
                                    inline_destructor  => 0,
                                    inline_constructor => 1,
                                   )
            }, undef, '... changed class to be immutable' );
    is( exception { $meta->make_mutable() }, undef, '... changed class to be mutable' );
    is( exception {$meta->make_immutable  }, undef, '... changed class to be immutable' );

    isnt( exception { $meta->add_method('xyz', sub{'xxx'})  }, undef, '... exception thrown as expected' );

    isnt( exception {
      $meta->add_attribute('fickle', accessor => 'fickle')
    }, undef, '... exception thrown as expected' );
    isnt( exception { $meta->remove_attribute('fickle') }, undef, '... exception thrown as expected' );

    my $reef = \ 'reef';
    isnt( exception { $meta->add_package_symbol('$ref', $reef) }, undef, '... exception thrown as expected' );
    isnt( exception { $meta->remove_package_symbol('$ref')     }, undef, '... exception thrown as expected' );

    ok( my @supers = $meta->superclasses,  '... got the superclasses okay');
    isnt( exception { $meta->superclasses('Foo') }, undef, '... set the superclasses' );

    ok( $meta->$_  , "... ${_} works")
      for qw(get_meta_instance       get_all_attributes
             class_precedence_list );
}

{
    Foo->meta->make_immutable;
    Bar->meta->make_immutable;
    Bar->meta->make_mutable;
}

done_testing;
