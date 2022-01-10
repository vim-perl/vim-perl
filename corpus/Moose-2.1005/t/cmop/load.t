use strict;
use warnings;

# for instance, App::ForkProve
my $preloaded;
BEGIN { $preloaded = exists $INC{'Class/MOP.pm'} }

use Test::More;

use Class::Load qw(is_class_loaded);

BEGIN {
    use_ok('Class::MOP');
    use_ok('Class::MOP::Mixin');
    use_ok('Class::MOP::Mixin::AttributeCore');
    use_ok('Class::MOP::Mixin::HasAttributes');
    use_ok('Class::MOP::Mixin::HasMethods');
    use_ok('Class::MOP::Package');
    use_ok('Class::MOP::Module');
    use_ok('Class::MOP::Class');
    use_ok('Class::MOP::Class::Immutable::Trait');
    use_ok('Class::MOP::Method');
    use_ok('Class::MOP::Method');
    use_ok('Class::MOP::Method::Wrapped');
    use_ok('Class::MOP::Method::Inlined');
    use_ok('Class::MOP::Method::Generated');
    use_ok('Class::MOP::Method::Accessor');
    use_ok('Class::MOP::Method::Constructor');
    use_ok('Class::MOP::Method::Meta');
    use_ok('Class::MOP::Method::Overload');
    use_ok('Class::MOP::Instance');
    use_ok('Class::MOP::Object');
}

# make sure we are tracking metaclasses correctly

my %METAS = (
    'Class::MOP::Attribute'         => Class::MOP::Attribute->meta,
    'Class::MOP::Method::Inlined' => Class::MOP::Method::Inlined->meta,
    'Class::MOP::Method::Generated' => Class::MOP::Method::Generated->meta,
    'Class::MOP::Method::Accessor'  => Class::MOP::Method::Accessor->meta,
    'Class::MOP::Method::Constructor' => Class::MOP::Method::Constructor->meta,
    'Class::MOP::Method::Meta' => Class::MOP::Method::Meta->meta,
    'Class::MOP::Method::Overload' => Class::MOP::Method::Overload->meta,
    'Class::MOP::Mixin'   => Class::MOP::Mixin->meta,
    'Class::MOP::Mixin::AttributeCore'   => Class::MOP::Mixin::AttributeCore->meta,
    'Class::MOP::Mixin::HasAttributes'   => Class::MOP::Mixin::HasAttributes->meta,
    'Class::MOP::Mixin::HasMethods'      => Class::MOP::Mixin::HasMethods->meta,
    'Class::MOP::Package'         => Class::MOP::Package->meta,
    'Class::MOP::Module'          => Class::MOP::Module->meta,
    'Class::MOP::Class'           => Class::MOP::Class->meta,
    'Class::MOP::Method'          => Class::MOP::Method->meta,
    'Class::MOP::Method::Wrapped' => Class::MOP::Method::Wrapped->meta,
    'Class::MOP::Instance'        => Class::MOP::Instance->meta,
    'Class::MOP::Object'          => Class::MOP::Object->meta,
    'Class::MOP::Class::Immutable::Trait' => Class::MOP::class_of('Class::MOP::Class::Immutable::Trait'),
    'Class::MOP::Class::Immutable::Class::MOP::Class' => Class::MOP::Class::Immutable::Class::MOP::Class->meta,
    'UNIVERSAL' => Class::MOP::class_of('UNIVERSAL'),
);

ok( is_class_loaded($_), '... ' . $_ . ' is loaded' )
    for keys %METAS;

# The trait shouldn't be made immutable, it doesn't actually do anything, and
# it doesn't even matter because it's not a class that will be
# instantiated. Making UNIVERSAL immutable just seems like a bad idea.
my %expect_mutable = map { $_ => 1 } qw( Class::MOP::Class::Immutable::Trait UNIVERSAL );

for my $meta (values %METAS) {
    if ( $expect_mutable{$meta->name} ) {
        ok( $meta->is_mutable(), '... ' . $meta->name . ' is mutable' );
    }
    else {
        ok( $meta->is_immutable(), '... ' . $meta->name . ' is immutable' );
    }
}

SKIP: {
    skip "this list may be incorrect if we preloaded things", 3 if $preloaded;
    is_deeply(
        {Class::MOP::get_all_metaclasses},
        \%METAS,
        '... got all the metaclasses'
    );

    is_deeply(
        [
            sort { $a->name cmp $b->name }
                 Class::MOP::get_all_metaclass_instances
        ],
        [
            Class::MOP::Attribute->meta,
            Class::MOP::Class->meta,
            Class::MOP::Class::Immutable::Class::MOP::Class->meta,
            Class::MOP::class_of('Class::MOP::Class::Immutable::Trait'),
            Class::MOP::Instance->meta,
            Class::MOP::Method->meta,
            Class::MOP::Method::Accessor->meta,
            Class::MOP::Method::Constructor->meta,
            Class::MOP::Method::Generated->meta,
            Class::MOP::Method::Inlined->meta,
            Class::MOP::Method::Meta->meta,
            Class::MOP::Method::Overload->meta,
            Class::MOP::Method::Wrapped->meta,
            Class::MOP::Mixin->meta,
            Class::MOP::Mixin::AttributeCore->meta,
            Class::MOP::Mixin::HasAttributes->meta,
            Class::MOP::Mixin::HasMethods->meta,
            Class::MOP::Module->meta,
            Class::MOP::Object->meta,
            Class::MOP::Package->meta,
            Class::MOP::class_of('UNIVERSAL'),
        ],
        '... got all the metaclass instances'
    );

    is_deeply(
        [ sort { $a cmp $b } Class::MOP::get_all_metaclass_names() ],
        [
            sort qw/
                Class::MOP::Attribute
                Class::MOP::Class
                Class::MOP::Class::Immutable::Class::MOP::Class
                Class::MOP::Class::Immutable::Trait
                Class::MOP::Mixin
                Class::MOP::Mixin::AttributeCore
                Class::MOP::Mixin::HasAttributes
                Class::MOP::Mixin::HasMethods
                Class::MOP::Instance
                Class::MOP::Method
                Class::MOP::Method::Accessor
                Class::MOP::Method::Constructor
                Class::MOP::Method::Generated
                Class::MOP::Method::Inlined
                Class::MOP::Method::Wrapped
                Class::MOP::Method::Meta
                Class::MOP::Method::Overload
                Class::MOP::Module
                Class::MOP::Object
                Class::MOP::Package
                UNIVERSAL
                /,
        ],
        '... got all the metaclass names'
    );
}

# testing the meta-circularity of the system

is(
    Class::MOP::Class->meta->meta, Class::MOP::Class->meta->meta->meta,
    '... Class::MOP::Class->meta->meta == Class::MOP::Class->meta->meta->meta'
);

is(
    Class::MOP::Class->meta->meta->meta, Class::MOP::Class->meta->meta->meta->meta,
    '... Class::MOP::Class->meta->meta->meta == Class::MOP::Class->meta->meta->meta->meta'
);

is(
    Class::MOP::Class->meta->meta, Class::MOP::Class->meta->meta->meta->meta,
    '... Class::MOP::Class->meta->meta == Class::MOP::Class->meta->meta->meta->meta'
);

is(
    Class::MOP::Class->meta->meta, Class::MOP::Class->meta->meta->meta->meta->meta,
    '... Class::MOP::Class->meta->meta == Class::MOP::Class->meta->meta->meta->meta->meta'
);

isa_ok(Class::MOP::Class->meta, 'Class::MOP::Class');

done_testing;
