use strict;
use warnings;

use Test::More;
use Test::Fatal;

{
    package Foo;
    use metaclass;
    sub foo {}
    Foo->meta->add_attribute('bar');
}

sub check_meta_sanity {
    my ($meta, $class) = @_;
    isa_ok($meta, 'Class::MOP::Class');
    is($meta->name, $class);
    ok($meta->has_method('foo'));
    isa_ok($meta->get_method('foo'), 'Class::MOP::Method');
    ok($meta->has_attribute('bar'));
    isa_ok($meta->get_attribute('bar'), 'Class::MOP::Attribute');
}

can_ok('Foo', 'meta');

my $meta = Foo->meta;
check_meta_sanity($meta, 'Foo');

is( exception {
    $meta = $meta->reinitialize($meta->name);
}, undef );
check_meta_sanity($meta, 'Foo');

is( exception {
    $meta = $meta->reinitialize($meta);
}, undef );
check_meta_sanity($meta, 'Foo');

like( exception {
    $meta->reinitialize('');
}, qr/You must pass a package name or an existing Class::MOP::Package instance/ );

like( exception {
    $meta->reinitialize($meta->new_object);
}, qr/You must pass a package name or an existing Class::MOP::Package instance/ );

{
    package Bar::Meta::Method;
    use base 'Class::MOP::Method';
    __PACKAGE__->meta->add_attribute('test', accessor => 'test');
}

{
    package Bar::Meta::Attribute;
    use base 'Class::MOP::Attribute';
    __PACKAGE__->meta->add_attribute('tset', accessor => 'tset');
}

{
    package Bar;
    use metaclass;
    Bar->meta->add_method('foo' => Bar::Meta::Method->wrap(sub {}, name => 'foo', package_name => 'Bar'));
    Bar->meta->add_attribute(Bar::Meta::Attribute->new('bar'));
}

$meta = Bar->meta;
check_meta_sanity($meta, 'Bar');
isa_ok(Bar->meta->get_method('foo'), 'Bar::Meta::Method');
isa_ok(Bar->meta->get_attribute('bar'), 'Bar::Meta::Attribute');
is( exception {
    $meta = $meta->reinitialize('Bar');
}, undef );
check_meta_sanity($meta, 'Bar');
isa_ok(Bar->meta->get_method('foo'), 'Bar::Meta::Method');
isa_ok(Bar->meta->get_attribute('bar'), 'Bar::Meta::Attribute');

Bar->meta->get_method('foo')->test('FOO');
Bar->meta->get_attribute('bar')->tset('OOF');

is(Bar->meta->get_method('foo')->test, 'FOO');
is(Bar->meta->get_attribute('bar')->tset, 'OOF');
is( exception {
    $meta = $meta->reinitialize('Bar');
}, undef );
is(Bar->meta->get_method('foo')->test, 'FOO');
is(Bar->meta->get_attribute('bar')->tset, 'OOF');

{
    package Baz::Meta::Attribute;
    use base 'Class::MOP::Attribute';
}

{
    package Baz::Meta::Method;
    use base 'Class::MOP::Method';
}

{
    package Baz;
    use metaclass meta_name => undef;

    sub foo {}
    Class::MOP::class_of('Baz')->add_attribute('bar');
}

$meta = Class::MOP::class_of('Baz');
check_meta_sanity($meta, 'Baz');
ok(!$meta->get_method('foo')->isa('Baz::Meta::Method'));
ok(!$meta->get_attribute('bar')->isa('Baz::Meta::Attribute'));
is( exception {
    $meta = $meta->reinitialize(
        'Baz',
        attribute_metaclass => 'Baz::Meta::Attribute',
        method_metaclass    => 'Baz::Meta::Method'
    );
}, undef );
check_meta_sanity($meta, 'Baz');
isa_ok($meta->get_method('foo'), 'Baz::Meta::Method');
isa_ok($meta->get_attribute('bar'), 'Baz::Meta::Attribute');

{
    package Quux;
    use metaclass
        attribute_metaclass => 'Bar::Meta::Attribute',
        method_metaclass    => 'Bar::Meta::Method';

    sub foo {}
    Quux->meta->add_attribute('bar');
}

$meta = Quux->meta;
check_meta_sanity($meta, 'Quux');
isa_ok(Quux->meta->get_method('foo'), 'Bar::Meta::Method');
isa_ok(Quux->meta->get_attribute('bar'), 'Bar::Meta::Attribute');
like( exception {
    $meta = $meta->reinitialize(
        'Quux',
        attribute_metaclass => 'Baz::Meta::Attribute',
        method_metaclass    => 'Baz::Meta::Method',
    );
}, qr/compatible/ );

{
    package Quuux::Meta::Attribute;
    use base 'Class::MOP::Attribute';

    sub install_accessors {}
}

{
    package Quuux;
    use metaclass;
    sub foo {}
    Quuux->meta->add_attribute('bar', reader => 'bar');
}

$meta = Quuux->meta;
check_meta_sanity($meta, 'Quuux');
ok($meta->has_method('bar'));
is( exception {
    $meta = $meta->reinitialize(
        'Quuux',
        attribute_metaclass => 'Quuux::Meta::Attribute',
    );
}, undef );
check_meta_sanity($meta, 'Quuux');
ok(!$meta->has_method('bar'));

{
    package Blah::Meta::Method;
    use base 'Class::MOP::Method';

    __PACKAGE__->meta->add_attribute('foo', reader => 'foo', default => 'TEST');
}

{
    package Blah::Meta::Attribute;
    use base 'Class::MOP::Attribute';

    __PACKAGE__->meta->add_attribute('oof', reader => 'oof', default => 'TSET');
}

{
    package Blah;
    use metaclass no_meta => 1;
    sub foo {}
    Class::MOP::class_of('Blah')->add_attribute('bar');
}

$meta = Class::MOP::class_of('Blah');
check_meta_sanity($meta, 'Blah');
is( exception {
    $meta = Class::MOP::Class->reinitialize(
        'Blah',
        attribute_metaclass => 'Blah::Meta::Attribute',
        method_metaclass    => 'Blah::Meta::Method',
    );
}, undef );
check_meta_sanity($meta, 'Blah');
can_ok($meta->get_method('foo'), 'foo');
is($meta->get_method('foo')->foo, 'TEST');
can_ok($meta->get_attribute('bar'), 'oof');
is($meta->get_attribute('bar')->oof, 'TSET');

done_testing;
