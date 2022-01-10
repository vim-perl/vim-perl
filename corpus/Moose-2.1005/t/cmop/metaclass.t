use strict;
use warnings;

use Test::More;

use metaclass;

{
    package FooMeta;
    use base 'Class::MOP::Class';

    package Foo;
    use metaclass 'FooMeta';
}

can_ok('Foo', 'meta');
isa_ok(Foo->meta, 'FooMeta');
isa_ok(Foo->meta, 'Class::MOP::Class');

{
    package BarMeta;
    use base 'Class::MOP::Class';

    package BarMeta::Attribute;
    use base 'Class::MOP::Attribute';

    package BarMeta::Method;
    use base 'Class::MOP::Method';

    package Bar;
    use metaclass 'BarMeta' => (
        'attribute_metaclass' => 'BarMeta::Attribute',
        'method_metaclass'    => 'BarMeta::Method',
    );
}

can_ok('Bar', 'meta');
isa_ok(Bar->meta, 'BarMeta');
isa_ok(Bar->meta, 'Class::MOP::Class');

is(Bar->meta->attribute_metaclass, 'BarMeta::Attribute', '... got the right attribute metaobject');
is(Bar->meta->method_metaclass, 'BarMeta::Method', '... got the right method metaobject');

{
    package Baz;
    use metaclass;
}

can_ok('Baz', 'meta');
isa_ok(Baz->meta, 'Class::MOP::Class');

eval {
    package Boom;
    metaclass->import('Foo');
};
ok($@, '... metaclasses must be subclass of Class::MOP::Class');

done_testing;
