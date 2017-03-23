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

    __PACKAGE__->meta->add_attribute('bar' => (
        reader  => 'bar',
        default => 'BAR',
    ));

    package Bar;

    use strict;
    use warnings;
    use metaclass;

    __PACKAGE__->meta->superclasses('Foo');

    __PACKAGE__->meta->add_attribute('baz' => (
        reader  => 'baz',
        default => sub { 'BAZ' },
    ));

    package Baz;

    use strict;
    use warnings;
    use metaclass;

    __PACKAGE__->meta->superclasses('Bar');

    __PACKAGE__->meta->add_attribute('bah' => (
        reader  => 'bah',
        default => 'BAH',
    ));

    package Buzz;

    use strict;
    use warnings;
    use metaclass;


    __PACKAGE__->meta->add_attribute('bar' => (
        accessor  => 'bar',
        predicate => 'has_bar',
        clearer   => 'clear_bar',
    ));

    __PACKAGE__->meta->add_attribute('bah' => (
        accessor  => 'bah',
        predicate => 'has_bah',
        clearer   => 'clear_bah',
        default   => 'BAH'
    ));

}

{
    my $meta = Foo->meta;
    is($meta->name, 'Foo', '... checking the Foo metaclass');

    {
        my $bar_accessor = $meta->get_method('bar');
        isa_ok($bar_accessor, 'Class::MOP::Method::Accessor');
        isa_ok($bar_accessor, 'Class::MOP::Method');

        ok(!$bar_accessor->is_inline, '... the bar accessor is not inlined');
    }

    ok(!$meta->is_immutable, '... our class is not immutable');

    is( exception {
        $meta->make_immutable(
            inline_constructor => 1,
            inline_accessors   => 0,
        );
    }, undef, '... changed Foo to be immutable' );

    ok($meta->is_immutable, '... our class is now immutable');
    isa_ok($meta, 'Class::MOP::Class');

    # they made a constructor for us :)
    can_ok('Foo', 'new');

    {
        my $foo = Foo->new;
        isa_ok($foo, 'Foo');
        is($foo->bar, 'BAR', '... got the right default value');
    }

    {
        my $foo = Foo->new(bar => 'BAZ');
        isa_ok($foo, 'Foo');
        is($foo->bar, 'BAZ', '... got the right parameter value');
    }

    # NOTE:
    # check that the constructor correctly handles inheritance
    {
        my $bar = Bar->new();
        isa_ok($bar, 'Bar');
        isa_ok($bar, 'Foo');
        is($bar->bar, 'BAR', '... got the right inherited parameter value');
        is($bar->baz, 'BAZ', '... got the right inherited parameter value');
    }

    # check out accessors too
    {
        my $bar_accessor = $meta->get_method('bar');
        isa_ok($bar_accessor, 'Class::MOP::Method::Accessor');
        isa_ok($bar_accessor, 'Class::MOP::Method');

        ok(!$bar_accessor->is_inline, '... the bar accessor is still not inlined');
    }
}

{
    my $meta = Bar->meta;
    is($meta->name, 'Bar', '... checking the Bar metaclass');

    {
        my $bar_accessor = $meta->find_method_by_name('bar');
        isa_ok($bar_accessor, 'Class::MOP::Method::Accessor');
        isa_ok($bar_accessor, 'Class::MOP::Method');

        ok(!$bar_accessor->is_inline, '... the bar accessor is not inlined');

        my $baz_accessor = $meta->get_method('baz');
        isa_ok($baz_accessor, 'Class::MOP::Method::Accessor');
        isa_ok($baz_accessor, 'Class::MOP::Method');

        ok(!$baz_accessor->is_inline, '... the baz accessor is not inlined');
    }

    ok(!$meta->is_immutable, '... our class is not immutable');

    is( exception {
        $meta->make_immutable(
            inline_constructor => 1,
            inline_accessors   => 1,
        );
    }, undef, '... changed Bar to be immutable' );

    ok($meta->is_immutable, '... our class is now immutable');
    isa_ok($meta, 'Class::MOP::Class');

    # they made a constructor for us :)
    can_ok('Bar', 'new');

    {
        my $bar = Bar->new;
        isa_ok($bar, 'Bar');
        is($bar->bar, 'BAR', '... got the right default value');
        is($bar->baz, 'BAZ', '... got the right default value');
    }

    {
        my $bar = Bar->new(bar => 'BAZ!', baz => 'BAR!');
        isa_ok($bar, 'Bar');
        is($bar->bar, 'BAZ!', '... got the right parameter value');
        is($bar->baz, 'BAR!', '... got the right parameter value');
    }

    # check out accessors too
    {
        my $bar_accessor = $meta->find_method_by_name('bar');
        isa_ok($bar_accessor, 'Class::MOP::Method::Accessor');
        isa_ok($bar_accessor, 'Class::MOP::Method');

        ok(!$bar_accessor->is_inline, '... the bar accessor is still not inlined');

        my $baz_accessor = $meta->get_method('baz');
        isa_ok($baz_accessor, 'Class::MOP::Method::Accessor');
        isa_ok($baz_accessor, 'Class::MOP::Method');

        ok($baz_accessor->is_inline, '... the baz accessor is not inlined');
    }
}

{
    my $meta = Baz->meta;
    is($meta->name, 'Baz', '... checking the Bar metaclass');

    {
        my $bar_accessor = $meta->find_method_by_name('bar');
        isa_ok($bar_accessor, 'Class::MOP::Method::Accessor');
        isa_ok($bar_accessor, 'Class::MOP::Method');

        ok(!$bar_accessor->is_inline, '... the bar accessor is not inlined');

        my $baz_accessor = $meta->find_method_by_name('baz');
        isa_ok($baz_accessor, 'Class::MOP::Method::Accessor');
        isa_ok($baz_accessor, 'Class::MOP::Method');

        ok($baz_accessor->is_inline, '... the baz accessor is inlined');

        my $bah_accessor = $meta->get_method('bah');
        isa_ok($bah_accessor, 'Class::MOP::Method::Accessor');
        isa_ok($bah_accessor, 'Class::MOP::Method');

        ok(!$bah_accessor->is_inline, '... the baz accessor is not inlined');
    }

    ok(!$meta->is_immutable, '... our class is not immutable');

    is( exception {
        $meta->make_immutable(
            inline_constructor => 0,
            inline_accessors   => 1,
        );
    }, undef, '... changed Bar to be immutable' );

    ok($meta->is_immutable, '... our class is now immutable');
    isa_ok($meta, 'Class::MOP::Class');

    ok(!Baz->meta->has_method('new'), '... no constructor was made');

    {
        my $baz = Baz->meta->new_object;
        isa_ok($baz, 'Bar');
        is($baz->bar, 'BAR', '... got the right default value');
        is($baz->baz, 'BAZ', '... got the right default value');
    }

    {
        my $baz = Baz->meta->new_object(bar => 'BAZ!', baz => 'BAR!', bah => 'BAH!');
        isa_ok($baz, 'Baz');
        is($baz->bar, 'BAZ!', '... got the right parameter value');
        is($baz->baz, 'BAR!', '... got the right parameter value');
        is($baz->bah, 'BAH!', '... got the right parameter value');
    }

    # check out accessors too
    {
        my $bar_accessor = $meta->find_method_by_name('bar');
        isa_ok($bar_accessor, 'Class::MOP::Method::Accessor');
        isa_ok($bar_accessor, 'Class::MOP::Method');

        ok(!$bar_accessor->is_inline, '... the bar accessor is still not inlined');

        my $baz_accessor = $meta->find_method_by_name('baz');
        isa_ok($baz_accessor, 'Class::MOP::Method::Accessor');
        isa_ok($baz_accessor, 'Class::MOP::Method');

        ok($baz_accessor->is_inline, '... the baz accessor is not inlined');

        my $bah_accessor = $meta->get_method('bah');
        isa_ok($bah_accessor, 'Class::MOP::Method::Accessor');
        isa_ok($bah_accessor, 'Class::MOP::Method');

        ok($bah_accessor->is_inline, '... the baz accessor is not inlined');
    }
}


{
  my $buzz;
  ::is( ::exception { $buzz = Buzz->meta->new_object }, undef, '...Buzz instantiated successfully' );
  ::ok(!$buzz->has_bar, '...bar is not set');
  ::is($buzz->bar, undef, '...bar returns undef');
  ::ok(!$buzz->has_bar, '...bar was not autovivified');

  $buzz->bar(undef);
  ::ok($buzz->has_bar, '...bar is set');
  ::is($buzz->bar, undef, '...bar is undef');
  $buzz->clear_bar;
  ::ok(!$buzz->has_bar, '...bar is no longerset');

  my $buzz2;
  ::is( ::exception { $buzz2 = Buzz->meta->new_object('bar' => undef) }, undef, '...Buzz instantiated successfully' );
  ::ok($buzz2->has_bar, '...bar is set');
  ::is($buzz2->bar, undef, '...bar is undef');

}

{
  my $buzz;
  ::is( ::exception { $buzz = Buzz->meta->new_object }, undef, '...Buzz instantiated successfully' );
  ::ok($buzz->has_bah, '...bah is set');
  ::is($buzz->bah, 'BAH', '...bah returns "BAH"' );

  my $buzz2;
  ::is( ::exception { $buzz2 = Buzz->meta->new_object('bah' => undef) }, undef, '...Buzz instantiated successfully' );
  ::ok($buzz2->has_bah, '...bah is set');
  ::is($buzz2->bah, undef, '...bah is undef');

}

done_testing;
