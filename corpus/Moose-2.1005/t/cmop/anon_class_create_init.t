use strict;
use warnings;

use Test::More;
use Test::Fatal;

use Class::MOP;

{
    package MyMeta;
    use base 'Class::MOP::Class';
    sub initialize {
        my $class = shift;
        my ( $package, %options ) = @_;
        ::cmp_ok( $options{foo}, 'eq', 'this',
            'option passed to initialize() on create_anon_class()' );
        return $class->SUPER::initialize( @_ );
    }

}

{
    my $anon = MyMeta->create_anon_class( foo => 'this' );
    isa_ok( $anon, 'MyMeta' );
}

my $instance;

{
    my $meta = Class::MOP::Class->create_anon_class;
    $instance = $meta->new_object;
}
{
    my $meta = Class::MOP::class_of($instance);
    Scalar::Util::weaken($meta);
    ok($meta, "anon class is kept alive by existing instances");

    undef $instance;
    ok(!$meta, "anon class is collected once instances go away");
}

{
    my $meta = Class::MOP::Class->create_anon_class;
    $meta->make_immutable;
    $instance = $meta->name->new;
}
{
    my $meta = Class::MOP::class_of($instance);
    Scalar::Util::weaken($meta);
    ok($meta, "anon class is kept alive by existing instances (immutable)");

    undef $instance;
    ok(!$meta, "anon class is collected once instances go away (immutable)");
}

{
    $instance = Class::MOP::Class->create('Foo')->new_object;
    my $meta = Class::MOP::Class->create_anon_class(superclasses => ['Foo']);
    $meta->rebless_instance($instance);
}
{
    my $meta = Class::MOP::class_of($instance);
    Scalar::Util::weaken($meta);
    ok($meta, "anon class is kept alive by existing instances");

    undef $instance;
    ok(!$meta, "anon class is collected once instances go away");
}

{
    {
        my $meta = Class::MOP::Class->create_anon_class;
        {
            my $submeta = Class::MOP::Class->create_anon_class(
                superclasses => [$meta->name]
            );
            $instance = $submeta->new_object;
        }
        {
            my $submeta = Class::MOP::class_of($instance);
            Scalar::Util::weaken($submeta);
            ok($submeta, "anon class is kept alive by existing instances");

            $meta->rebless_instance_back($instance);
            ok(!$submeta, "reblessing away loses the metaclass");
        }
    }

    my $meta = Class::MOP::class_of($instance);
    Scalar::Util::weaken($meta);
    ok($meta, "anon class is kept alive by existing instances");
}

{
    my $submeta = Class::MOP::Class->create_anon_class(
        superclasses => [Class::MOP::Class->create_anon_class->name],
    );
    my @superclasses = $submeta->superclasses;
    ok(Class::MOP::class_of($superclasses[0]),
       "superclasses are kept alive by their subclasses");
}

{
    my $meta_name;
    {
        my $meta = Class::MOP::Class->create_anon_class(
            superclasses => ['Class::MOP::Class'],
        );
        $meta_name = $meta->name;
        ok(Class::MOP::metaclass_is_weak($meta_name),
           "default is for anon metaclasses to be weakened");
    }
    ok(!Class::MOP::class_of($meta_name),
       "and weak metaclasses go away when all refs do");
    {
        my $meta = Class::MOP::Class->create_anon_class(
            superclasses => ['Class::MOP::Class'],
            weaken => 0,
        );
        $meta_name = $meta->name;
        ok(!Class::MOP::metaclass_is_weak($meta_name),
           "anon classes can be told not to weaken");
    }
    ok(Class::MOP::class_of($meta_name), "metaclass still exists");
    {
        my $bar_meta;
        is( exception {
            $bar_meta = $meta_name->initialize('Bar');
        }, undef, "we can use the name on its own" );
        isa_ok($bar_meta, $meta_name);
    }
}

{
    my $meta = Class::MOP::Class->create(
        'Baz',
        weaken => 1,
    );
    $instance = $meta->new_object;
}
{
    my $meta = Class::MOP::class_of($instance);
    Scalar::Util::weaken($meta);
    ok($meta, "weak class is kept alive by existing instances");

    undef $instance;
    ok(!$meta, "weak class is collected once instances go away");
}

done_testing;
