use strict;
use warnings;

use Test::More;
use Test::Fatal;

use Class::MOP;

my $FOO_ATTR = Class::MOP::Attribute->new('$foo');
my $BAR_ATTR = Class::MOP::Attribute->new('$bar' => (
    accessor => 'bar'
));
my $BAZ_ATTR = Class::MOP::Attribute->new('$baz' => (
    reader => 'get_baz',
    writer => 'set_baz',
));

my $BAR_ATTR_2 = Class::MOP::Attribute->new('$bar');

my $FOO_ATTR_2 = Class::MOP::Attribute->new('$foo' => (
    accessor => 'foo',
    builder => 'build_foo'
));

is($FOO_ATTR->name, '$foo', '... got the attributes name correctly');
is($BAR_ATTR->name, '$bar', '... got the attributes name correctly');
is($BAZ_ATTR->name, '$baz', '... got the attributes name correctly');

{
    package Foo;
    use metaclass;

    my $meta = Foo->meta;
    ::is( ::exception {
        $meta->add_attribute($FOO_ATTR);
    }, undef, '... we added an attribute to Foo successfully' );
    ::ok($meta->has_attribute('$foo'), '... Foo has $foo attribute');
    ::is($meta->get_attribute('$foo'), $FOO_ATTR, '... got the right attribute back for Foo');

    ::ok(!$meta->has_method('foo'), '... no accessor created');

    ::is( ::exception {
        $meta->add_attribute($BAR_ATTR_2);
    }, undef, '... we added an attribute to Foo successfully' );
    ::ok($meta->has_attribute('$bar'), '... Foo has $bar attribute');
    ::is($meta->get_attribute('$bar'), $BAR_ATTR_2, '... got the right attribute back for Foo');

    ::ok(!$meta->has_method('bar'), '... no accessor created');
}
{
    package Bar;
    our @ISA = ('Foo');

    my $meta = Bar->meta;
    ::is( ::exception {
        $meta->add_attribute($BAR_ATTR);
    }, undef, '... we added an attribute to Bar successfully' );
    ::ok($meta->has_attribute('$bar'), '... Bar has $bar attribute');
    ::is($meta->get_attribute('$bar'), $BAR_ATTR, '... got the right attribute back for Bar');

    my $attr = $meta->get_attribute('$bar');
    ::is($attr->get_read_method,  'bar', '... got the right read method for Bar');
    ::is($attr->get_write_method, 'bar', '... got the right write method for Bar');

    ::ok($meta->has_method('bar'), '... an accessor has been created');
    ::isa_ok($meta->get_method('bar'), 'Class::MOP::Method::Accessor');
}
{
    package Baz;
    our @ISA = ('Bar');

    my $meta = Baz->meta;
    ::is( ::exception {
        $meta->add_attribute($BAZ_ATTR);
    }, undef, '... we added an attribute to Baz successfully' );
    ::ok($meta->has_attribute('$baz'), '... Baz has $baz attribute');
    ::is($meta->get_attribute('$baz'), $BAZ_ATTR, '... got the right attribute back for Baz');

    my $attr = $meta->get_attribute('$baz');
    ::is($attr->get_read_method,  'get_baz', '... got the right read method for Baz');
    ::is($attr->get_write_method, 'set_baz', '... got the right write method for Baz');

    ::ok($meta->has_method('get_baz'), '... a reader has been created');
    ::ok($meta->has_method('set_baz'), '... a writer has been created');

    ::isa_ok($meta->get_method('get_baz'), 'Class::MOP::Method::Accessor');
    ::isa_ok($meta->get_method('set_baz'), 'Class::MOP::Method::Accessor');
}

{
    package Foo2;
    use metaclass;

    my $meta = Foo2->meta;
    $meta->add_attribute(
        Class::MOP::Attribute->new( '$foo2' => ( reader => 'foo2' ) ) );

    ::ok( $meta->has_method('foo2'), '... a reader has been created' );

    my $attr = $meta->get_attribute('$foo2');
    ::is( $attr->get_read_method, 'foo2',
        '... got the right read method for Foo2' );
    ::is( $attr->get_write_method, undef,
        '... got undef for the writer with a read-only attribute in Foo2' );
}

{
    my $meta = Baz->meta;
    isa_ok($meta, 'Class::MOP::Class');

    is($meta->find_attribute_by_name('$bar'), $BAR_ATTR, '... got the right attribute for "bar"');
    is($meta->find_attribute_by_name('$baz'), $BAZ_ATTR, '... got the right attribute for "baz"');
    is($meta->find_attribute_by_name('$foo'), $FOO_ATTR, '... got the right attribute for "foo"');

    is_deeply(
        [ sort { $a->name cmp $b->name } $meta->get_all_attributes() ],
        [
            $BAR_ATTR,
            $BAZ_ATTR,
            $FOO_ATTR,
        ],
        '... got the right list of applicable attributes for Baz');

    is_deeply(
        [ map { $_->associated_class } sort { $a->name cmp $b->name } $meta->get_all_attributes() ],
        [ Bar->meta, Baz->meta, Foo->meta ],
        '... got the right list of associated classes from the applicable attributes for Baz');

    my $attr;
    is( exception {
        $attr = $meta->remove_attribute('$baz');
    }, undef, '... removed the $baz attribute successfully' );
    is($attr, $BAZ_ATTR, '... got the right attribute back for Baz');

    ok(!$meta->has_attribute('$baz'), '... Baz no longer has $baz attribute');
    is($meta->get_attribute('$baz'), undef, '... Baz no longer has $baz attribute');

    ok(!$meta->has_method('get_baz'), '... a reader has been removed');
    ok(!$meta->has_method('set_baz'), '... a writer has been removed');

    is_deeply(
        [ sort { $a->name cmp $b->name } $meta->get_all_attributes() ],
        [
            $BAR_ATTR,
            $FOO_ATTR,
        ],
        '... got the right list of applicable attributes for Baz');

    is_deeply(
        [ map { $_->associated_class } sort { $a->name cmp $b->name } $meta->get_all_attributes() ],
        [ Bar->meta, Foo->meta ],
        '... got the right list of associated classes from the applicable attributes for Baz');

     {
         my $attr;
         is( exception {
             $attr = Bar->meta->remove_attribute('$bar');
         }, undef, '... removed the $bar attribute successfully' );
         is($attr, $BAR_ATTR, '... got the right attribute back for Bar');

         ok(!Bar->meta->has_attribute('$bar'), '... Bar no longer has $bar attribute');

         ok(!Bar->meta->has_method('bar'), '... a accessor has been removed');
     }

     is_deeply(
         [ sort { $a->name cmp $b->name } $meta->get_all_attributes() ],
         [
             $BAR_ATTR_2,
             $FOO_ATTR,
         ],
         '... got the right list of applicable attributes for Baz');

     is_deeply(
         [ map { $_->associated_class } sort { $a->name cmp $b->name } $meta->get_all_attributes() ],
         [ Foo->meta, Foo->meta ],
         '... got the right list of associated classes from the applicable attributes for Baz');

    # remove attribute which is not there
    my $val;
    is( exception {
        $val = $meta->remove_attribute('$blammo');
    }, undef, '... attempted to remove the non-existent $blammo attribute' );
    is($val, undef, '... got the right value back (undef)');

}

{
    package Buzz;
    use metaclass;
    use Scalar::Util qw/blessed/;

    my $meta = Buzz->meta;
    ::is( ::exception {
        $meta->add_attribute($FOO_ATTR_2);
    }, undef, '... we added an attribute to Buzz successfully' );

    ::is( ::exception {
        $meta->add_attribute(
            Class::MOP::Attribute->new(
                 '$bar' => (
                            accessor  => 'bar',
                            predicate => 'has_bar',
                            clearer   => 'clear_bar',
                           )
                )
        );
    }, undef, '... we added an attribute to Buzz successfully' );

    ::is( ::exception {
        $meta->add_attribute(
            Class::MOP::Attribute->new(
                 '$bah' => (
                            accessor  => 'bah',
                            predicate => 'has_bah',
                            clearer   => 'clear_bah',
                            default   => 'BAH',
                           )
                )
        );
    }, undef, '... we added an attribute to Buzz successfully' );

    ::is( ::exception {
        $meta->add_method(build_foo => sub{ blessed shift; });
    }, undef, '... we added a method to Buzz successfully' );
}



for(1 .. 2){
  my $buzz;
  ::is( ::exception { $buzz = Buzz->meta->new_object }, undef, '...Buzz instantiated successfully' );
  ::is($buzz->foo, 'Buzz', '...foo builder works as expected');
  ::ok(!$buzz->has_bar, '...bar is not set');
  ::is($buzz->bar, undef, '...bar returns undef');
  ::ok(!$buzz->has_bar, '...bar was not autovivified');

  $buzz->bar(undef);
  ::ok($buzz->has_bar, '...bar is set');
  ::is($buzz->bar, undef, '...bar is undef');
  $buzz->clear_bar;
  ::ok(!$buzz->has_bar, '...bar is no longerset');

  my $buzz2;
  ::is( ::exception { $buzz2 = Buzz->meta->new_object('$bar' => undef) }, undef, '...Buzz instantiated successfully' );
  ::ok($buzz2->has_bar, '...bar is set');
  ::is($buzz2->bar, undef, '...bar is undef');

  my $buzz3;
  ::is( ::exception { $buzz3 = Buzz->meta->new_object }, undef, '...Buzz instantiated successfully' );
  ::ok($buzz3->has_bah, '...bah is set');
  ::is($buzz3->bah, 'BAH', '...bah returns "BAH" ');

  my $buzz4;
  ::is( ::exception { $buzz4 = Buzz->meta->new_object('$bah' => undef) }, undef, '...Buzz instantiated successfully' );
  ::ok($buzz4->has_bah, '...bah is set');
  ::is($buzz4->bah, undef, '...bah is undef');

  Buzz->meta->make_immutable();
}

done_testing;
