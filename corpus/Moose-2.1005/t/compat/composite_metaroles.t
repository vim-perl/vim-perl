#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::Fatal;
use Test::Moose;

{
    package Foo::Role;
    use Moose::Role;
}

{
    package Bar::Role;
    use Moose::Role;
}

{
    package Parent;
    use Moose;
    Moose::Util::MetaRole::apply_metaroles(
        for => __PACKAGE__,
        class_metaroles => { class => ['Foo::Role'] },
    );
}

{
    package Child;
    use Moose;
    Moose::Util::MetaRole::apply_metaroles(
        for => __PACKAGE__,
        class_metaroles => { class => ['Foo::Role', 'Bar::Role'] },
    );
    ::is( ::exception { extends 'Parent' }, undef );
}

with_immutable {
    isa_ok('Child', 'Parent');
    isa_ok(Child->meta, Parent->meta->_real_ref_name);
    does_ok(Parent->meta, 'Foo::Role');
    does_ok(Child->meta, 'Foo::Role');
    does_ok(Child->meta, 'Bar::Role');
} 'Parent', 'Child';

done_testing;
