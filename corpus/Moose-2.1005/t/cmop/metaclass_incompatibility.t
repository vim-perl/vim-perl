use strict;
use warnings;

use Test::More;
use Test::Fatal;

use metaclass;

my %metaclass_attrs;
BEGIN {
    %metaclass_attrs = (
        'Instance'            => 'instance_metaclass',
        'Attribute'           => 'attribute_metaclass',
        'Method'              => 'method_metaclass',
        'Method::Wrapped'     => 'wrapped_method_metaclass',
        'Method::Constructor' => 'constructor_class',
    );

    # meta classes
    for my $suffix ('Class', keys %metaclass_attrs) {
        Class::MOP::Class->create(
            "Foo::Meta::$suffix",
            superclasses => ["Class::MOP::$suffix"]
        );
        $INC{"Foo/Meta/$suffix.pm"} = __FILE__;
        Class::MOP::Class->create(
            "Bar::Meta::$suffix",
            superclasses => ["Class::MOP::$suffix"]
        );
        $INC{"Bar/Meta/$suffix.pm"} = __FILE__;
        Class::MOP::Class->create(
            "FooBar::Meta::$suffix",
            superclasses => ["Foo::Meta::$suffix", "Bar::Meta::$suffix"]
        );
        $INC{"FooBar/Meta/$suffix.pm"} = __FILE__;
    }
}

# checking...

is( exception {
    Foo::Meta::Class->create('Foo')
}, undef, '... Foo.meta => Foo::Meta::Class is compatible' );
is( exception {
    Bar::Meta::Class->create('Bar')
}, undef, '... Bar.meta => Bar::Meta::Class is compatible' );

like( exception {
    Bar::Meta::Class->create('Foo::Foo', superclasses => ['Foo'])
}, qr/compatible/, '... Foo::Foo.meta => Bar::Meta::Class is not compatible' );
like( exception {
    Foo::Meta::Class->create('Bar::Bar', superclasses => ['Bar'])
}, qr/compatible/, '... Bar::Bar.meta => Foo::Meta::Class is not compatible' );

is( exception {
    FooBar::Meta::Class->create('FooBar', superclasses => ['Foo'])
}, undef, '... FooBar.meta => FooBar::Meta::Class is compatible' );
is( exception {
    FooBar::Meta::Class->create('FooBar2', superclasses => ['Bar'])
}, undef, '... FooBar2.meta => FooBar::Meta::Class is compatible' );

Foo::Meta::Class->create(
    'Foo::All',
    map { $metaclass_attrs{$_} => "Foo::Meta::$_" } keys %metaclass_attrs,
);

like( exception {
    Bar::Meta::Class->create(
        'Foo::All::Sub::Class',
        superclasses => ['Foo::All'],
        map { $metaclass_attrs{$_} => "Foo::Meta::$_" } keys %metaclass_attrs,
    )
}, qr/compatible/, 'incompatible Class metaclass' );
for my $suffix (keys %metaclass_attrs) {
    like( exception {
        Foo::Meta::Class->create(
            "Foo::All::Sub::$suffix",
            superclasses => ['Foo::All'],
            (map { $metaclass_attrs{$_} => "Foo::Meta::$_" } keys %metaclass_attrs),
            $metaclass_attrs{$suffix} => "Bar::Meta::$suffix",
        )
    }, qr/compatible/, "incompatible $suffix metaclass" );
}

# fixing...

is( exception {
    Class::MOP::Class->create('Foo::Foo::CMOP', superclasses => ['Foo'])
}, undef, 'metaclass fixing fixes a cmop metaclass, when the parent has a subclass' );
isa_ok(Foo::Foo::CMOP->meta, 'Foo::Meta::Class');
is( exception {
    Class::MOP::Class->create('Bar::Bar::CMOP', superclasses => ['Bar'])
}, undef, 'metaclass fixing fixes a cmop metaclass, when the parent has a subclass' );
isa_ok(Bar::Bar::CMOP->meta, 'Bar::Meta::Class');

is( exception {
    Class::MOP::Class->create(
        'Foo::All::Sub::CMOP::Class',
        superclasses => ['Foo::All'],
        map { $metaclass_attrs{$_} => "Foo::Meta::$_" } keys %metaclass_attrs,
    )
}, undef, 'metaclass fixing works with other non-default metaclasses' );
isa_ok(Foo::All::Sub::CMOP::Class->meta, 'Foo::Meta::Class');

for my $suffix (keys %metaclass_attrs) {
    is( exception {
        Foo::Meta::Class->create(
            "Foo::All::Sub::CMOP::$suffix",
            superclasses => ['Foo::All'],
            (map { $metaclass_attrs{$_} => "Foo::Meta::$_" } keys %metaclass_attrs),
            $metaclass_attrs{$suffix} => "Class::MOP::$suffix",
        )
    }, undef, "$metaclass_attrs{$suffix} fixing works with other non-default metaclasses" );
    for my $suffix2 (keys %metaclass_attrs) {
        my $method = $metaclass_attrs{$suffix2};
        isa_ok("Foo::All::Sub::CMOP::$suffix"->meta->$method, "Foo::Meta::$suffix2");
    }
}

# initializing...

{
    package Foo::NoMeta;
}

Class::MOP::Class->create('Foo::NoMeta::Sub', superclasses => ['Foo::NoMeta']);
ok(!Foo::NoMeta->can('meta'), "non-cmop superclass doesn't get methods installed");
isa_ok(Class::MOP::class_of('Foo::NoMeta'), 'Class::MOP::Class');
isa_ok(Foo::NoMeta::Sub->meta, 'Class::MOP::Class');

{
    package Foo::NoMeta2;
}
Foo::Meta::Class->create('Foo::NoMeta2::Sub', superclasses => ['Foo::NoMeta2']);
ok(!Foo::NoMeta->can('meta'), "non-cmop superclass doesn't get methods installed");
isa_ok(Class::MOP::class_of('Foo::NoMeta2'), 'Class::MOP::Class');
isa_ok(Foo::NoMeta2::Sub->meta, 'Foo::Meta::Class');


BEGIN {
    Foo::Meta::Class->create('Foo::WithMeta');
    $INC{'Foo/WithMeta.pm'} = __FILE__;
}
{
    package Foo::WithMeta::Sub;
    use base 'Foo::WithMeta';
}
Class::MOP::Class->create(
    'Foo::WithMeta::Sub::Sub',
    superclasses => ['Foo::WithMeta::Sub']
);

isa_ok(Class::MOP::class_of('Foo::WithMeta'), 'Foo::Meta::Class');
isa_ok(Class::MOP::class_of('Foo::WithMeta::Sub'), 'Foo::Meta::Class');
isa_ok(Class::MOP::class_of('Foo::WithMeta::Sub::Sub'), 'Foo::Meta::Class');

BEGIN {
    Foo::Meta::Class->create('Foo::WithMeta2');
    $INC{'Foo/WithMeta2.pm'} = __FILE__;
}
{
    package Foo::WithMeta2::Sub;
    use base 'Foo::WithMeta2';
}
{
    package Foo::WithMeta2::Sub::Sub;
    use base 'Foo::WithMeta2::Sub';
}
Class::MOP::Class->create(
    'Foo::WithMeta2::Sub::Sub::Sub',
    superclasses => ['Foo::WithMeta2::Sub::Sub']
);

isa_ok(Class::MOP::class_of('Foo::WithMeta2'), 'Foo::Meta::Class');
isa_ok(Class::MOP::class_of('Foo::WithMeta2::Sub'), 'Foo::Meta::Class');
isa_ok(Class::MOP::class_of('Foo::WithMeta2::Sub::Sub'), 'Foo::Meta::Class');
isa_ok(Class::MOP::class_of('Foo::WithMeta2::Sub::Sub::Sub'), 'Foo::Meta::Class');

Class::MOP::Class->create(
    'Foo::Reverse::Sub::Sub',
    superclasses => ['Foo::Reverse::Sub'],
);
eval "package Foo::Reverse::Sub; use base 'Foo::Reverse';";
Foo::Meta::Class->create(
    'Foo::Reverse',
);
isa_ok(Class::MOP::class_of('Foo::Reverse'), 'Foo::Meta::Class');
{ local $TODO = 'No idea how to handle case where child class is created before parent';
isa_ok(Class::MOP::class_of('Foo::Reverse::Sub'), 'Foo::Meta::Class');
isa_ok(Class::MOP::class_of('Foo::Reverse::Sub::Sub'), 'Foo::Meta::Class');
}

# unsafe fixing...

{
    Class::MOP::Class->create(
        'Foo::Unsafe',
        attribute_metaclass => 'Foo::Meta::Attribute',
    );
    my $meta = Class::MOP::Class->create(
        'Foo::Unsafe::Sub',
    );
    $meta->add_attribute(foo => reader => 'foo');
    like( exception { $meta->superclasses('Foo::Unsafe') }, qr/compatibility.*pristine/, "can't switch out the attribute metaclass of a class that already has attributes" );
}

# immutability...

{
    my $foometa = Foo::Meta::Class->create(
        'Foo::Immutable',
    );
    $foometa->make_immutable;
    my $barmeta = Class::MOP::Class->create(
        'Bar::Mutable',
    );
    my $bazmeta = Class::MOP::Class->create(
        'Baz::Mutable',
    );
    $bazmeta->superclasses($foometa->name);
    is( exception { $bazmeta->superclasses($barmeta->name) }, undef, "can still set superclasses" );
    ok(!$bazmeta->is_immutable,
       "immutable superclass doesn't make this class immutable");
    is( exception { $bazmeta->make_immutable }, undef, "can still make immutable" );
}

# nonexistent metaclasses

Class::MOP::Class->create(
    'Weird::Meta::Method::Destructor',
    superclasses => ['Class::MOP::Method'],
);

is( exception {
    Class::MOP::Class->create(
        'Weird::Class',
        destructor_class => 'Weird::Meta::Method::Destructor',
    );
}, undef, "defined metaclass in child with defined metaclass in parent is fine" );

is(Weird::Class->meta->destructor_class, 'Weird::Meta::Method::Destructor',
   "got the right destructor class");

is( exception {
    Class::MOP::Class->create(
        'Weird::Class::Sub',
        superclasses     => ['Weird::Class'],
        destructor_class => undef,
    );
}, undef, "undef metaclass in child with defined metaclass in parent can be fixed" );

is(Weird::Class::Sub->meta->destructor_class, 'Weird::Meta::Method::Destructor',
   "got the right destructor class");

is( exception {
    Class::MOP::Class->create(
        'Weird::Class::Sub2',
        destructor_class => undef,
    );
}, undef, "undef metaclass in child with defined metaclass in parent can be fixed" );

is( exception {
    Weird::Class::Sub2->meta->superclasses('Weird::Class');
}, undef, "undef metaclass in child with defined metaclass in parent can be fixed" );

is(Weird::Class::Sub->meta->destructor_class, 'Weird::Meta::Method::Destructor',
   "got the right destructor class");

done_testing;
