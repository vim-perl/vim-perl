use strict;
use warnings;

use Test::More;
use Test::Moose;

{
    package Role::A;
    use Moose::Role
}

{
    package Role::B;
    use Moose::Role
}

{
    package Foo;
    use Moose;
}

{
    package Bar;
    use Moose;

    with 'Role::A';
}

{
    package Baz;
    use Moose;

    with qw( Role::A Role::B );
}

{
    package Foo::Child;
    use Moose;

    extends 'Foo';
}

{
    package Bar::Child;
    use Moose;

    extends 'Bar';
}

{
    package Baz::Child;
    use Moose;

    extends 'Baz';
}

with_immutable {

    for my $thing ( 'Foo', Foo->new, 'Foo::Child', Foo::Child->new ) {
        my $name = ref $thing ? (ref $thing) . ' object' : "$thing class";
        $name .= ' (immutable)' if $thing->meta->is_immutable;

        ok(
            !$thing->does('Role::A'),
            "$name does not do Role::A"
        );
        ok(
            !$thing->does('Role::B'),
            "$name does not do Role::B"
        );

        ok(
            !$thing->does( Role::A->meta ),
            "$name does not do Role::A (passed as object)"
        );
        ok(
            !$thing->does( Role::B->meta ),
            "$name does not do Role::B (passed as object)"
        );

        ok(
            !$thing->DOES('Role::A'),
            "$name does not do Role::A (using DOES)"
        );
        ok(
            !$thing->DOES('Role::B'),
            "$name does not do Role::B (using DOES)"
        );
    }

    for my $thing ( 'Bar', Bar->new, 'Bar::Child', Bar::Child->new ) {
        my $name = ref $thing ? (ref $thing) . ' object' : "$thing class";
        $name .= ' (immutable)' if $thing->meta->is_immutable;

        ok(
            $thing->does('Role::A'),
            "$name does Role::A"
        );
        ok(
            !$thing->does('Role::B'),
            "$name does not do Role::B"
        );

        ok(
            $thing->does( Role::A->meta ),
            "$name does Role::A (passed as object)"
        );
        ok(
            !$thing->does( Role::B->meta ),
            "$name does not do Role::B (passed as object)"
        );

        ok(
            $thing->DOES('Role::A'),
            "$name does Role::A (using DOES)"
        );
        ok(
            !$thing->DOES('Role::B'),
            "$name does not do Role::B (using DOES)"
        );
    }

    for my $thing ( 'Baz', Baz->new, 'Baz::Child', Baz::Child->new ) {
        my $name = ref $thing ? (ref $thing) . ' object' : "$thing class";
        $name .= ' (immutable)' if $thing->meta->is_immutable;

        ok(
            $thing->does('Role::A'),
            "$name does Role::A"
        );
        ok(
            $thing->does('Role::B'),
            "$name does Role::B"
        );

        ok(
            $thing->does( Role::A->meta ),
            "$name does Role::A (passed as object)"
        );
        ok(
            $thing->does( Role::B->meta ),
            "$name does Role::B (passed as object)"
        );

        ok(
            $thing->DOES('Role::A'),
            "$name does Role::A (using DOES)"
        );
        ok(
            $thing->DOES('Role::B'),
            "$name does Role::B (using DOES)"
        );
    }

}
qw( Foo Bar Baz Foo::Child Bar::Child Baz::Child );

done_testing;
